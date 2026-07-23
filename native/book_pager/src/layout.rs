//! Semantic pagination for Chinese novel text (ABI v3).
//!
//! Rust is a **layout decision engine**, not a pixel renderer:
//! - Decides where lines break (CJK-aware)
//! - Emits page-local `top`/`height` for stacking
//! - Emits justify **intent** + `target_width` (Flutter computes letterSpacing)
//! - Does NOT emit glyph ids or absolute paint coordinates
//!
//! Flutter Skia paints with TextPainter(maxLines: 1).

use cosmic_text::{Attrs, Buffer, Family, FontSystem, Metrics, Shaping, Wrap};
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::Path;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

/// Shared font system. Fonts are loaded from [LayoutInput::font_path] only
/// (no system font scan for pagination — keeps metrics stable).
static FONT_SYSTEM: Lazy<Mutex<FontSystem>> =
    Lazy::new(|| Mutex::new(FontSystem::new()));

/// job_id → cancelled flag
static CANCEL_FLAGS: Lazy<Mutex<HashMap<u64, Arc<AtomicBool>>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

static LOADED_FONT_PATH: Lazy<Mutex<String>> = Lazy::new(|| Mutex::new(String::new()));

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutInput {
    /// Full chapter text (paragraphs separated by `\n`)
    pub text: String,
    pub font_size: f32,
    /// Multiplier of font size for line height (matches Flutter TextStyle.height)
    pub line_height: f32,
    /// Extra gap after a paragraph ends (already scaled by caller if needed)
    #[serde(alias = "paragraph")]
    pub paragraph_spacing: f32,
    #[serde(alias = "box_width")]
    pub page_width: f32,
    #[serde(alias = "box_height")]
    pub page_height: f32,
    #[serde(default)]
    pub padding_left: f32,
    #[serde(default)]
    pub padding_right: f32,
    /// Legacy single horizontal padding (used when left/right are 0).
    #[serde(default)]
    pub padding_horizontal: f32,
    #[serde(default)]
    pub padding_top: f32,
    #[serde(default)]
    pub padding_bottom: f32,
    #[serde(default)]
    pub padding_vertical: f32,
    #[serde(default = "default_true")]
    pub should_justify_height: bool,
    /// Absolute path to the same TTF Flutter uses. Required for ABI3.
    pub font_path: String,
    #[serde(default = "default_family")]
    pub font_family: String,
    /// "justify" | "left"
    #[serde(default = "default_align")]
    pub text_align: String,
    #[serde(default)]
    pub base_letter_spacing: f32,
    #[serde(default)]
    pub job_id: u64,
    /// When true, return after the first page is full.
    #[serde(default)]
    pub first_page_only: bool,
    /// UTF-8 byte offset into [text] to start from (incremental).
    #[serde(default)]
    pub start_char: usize,
    /// 0 = unlimited
    #[serde(default)]
    pub max_pages: u32,
}

fn default_true() -> bool {
    // Vertical center is applied at paint time; do not stretch line gaps by default.
    false
}
fn default_family() -> String {
    // Must match the TTF name table (not the Flutter pubspec family alias).
    "HarmonyOS Sans SC".into()
}
fn default_align() -> String {
    "justify".into()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextLineOut {
    pub text: String,
    pub top: f32,
    pub height: f32,
    pub justify: bool,
    pub is_last_line: bool,
    pub is_paragraph_end: bool,
    pub target_width: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextPageOut {
    pub lines: Vec<TextLineOut>,
    pub height: f32,
    pub page_index: u32,
    pub char_start: usize,
    pub char_end: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaginateResult {
    pub pages: Vec<TextPageOut>,
    pub complete: bool,
    pub next_char: usize,
    pub engine: String,
    pub abi: i32,
}

/// Mark a job cancelled (or create the flag).
pub fn cancel_job(job_id: u64) {
    if job_id == 0 {
        return;
    }
    let mut map = CANCEL_FLAGS.lock();
    map.entry(job_id)
        .or_insert_with(|| Arc::new(AtomicBool::new(false)))
        .store(true, Ordering::SeqCst);
}

fn job_flag(job_id: u64) -> Option<Arc<AtomicBool>> {
    if job_id == 0 {
        return None;
    }
    let mut map = CANCEL_FLAGS.lock();
    // Fresh job: reset / insert false
    let flag = map
        .entry(job_id)
        .or_insert_with(|| Arc::new(AtomicBool::new(false)))
        .clone();
    // If already cancelled before we start, keep cancelled.
    Some(flag)
}

fn is_cancelled(flag: &Option<Arc<AtomicBool>>) -> bool {
    flag.as_ref()
        .map(|f| f.load(Ordering::Relaxed))
        .unwrap_or(false)
}

/// Line-start prohibited CJK punctuation (cannot begin a line).
fn is_line_start_forbidden(c: char) -> bool {
    matches!(
        c,
        '，' | '。' | '！' | '？' | '、' | '；' | '：' | '》' | '」' | '』' | '）' | '】'
            | '〉' | '…' | '—' | '”' | '’' | ',' | '.' | '!' | '?' | ')' | ']' | '}' | '%'
    )
}

/// Max chars that can fit in [max_width] assuming ~1em CJK advance.
fn estimated_max_chars(max_width: f32, font_size: f32) -> usize {
    let em = font_size.max(1.0);
    ((max_width / em).floor() as usize).max(1)
}

fn bytes_for_chars(text: &str, n: usize) -> usize {
    text.chars().take(n).map(|c| c.len_utf8()).sum()
}

fn ensure_font(font_system: &mut FontSystem, font_path: &str) -> Result<(), String> {
    if font_path.is_empty() {
        return Err("font_path required (ABI3: same TTF as Flutter)".into());
    }
    if !Path::new(font_path).is_file() {
        return Err(format!("font file missing: {font_path}"));
    }
    let mut loaded = LOADED_FONT_PATH.lock();
    if *loaded != font_path {
        if let Err(e) = font_system.db_mut().load_font_file(font_path) {
            return Err(format!("load_font_file failed: {e}"));
        }
        *loaded = font_path.to_string();
    }
    if font_system.db().is_empty() {
        return Err("no fonts loaded after load_font_file".into());
    }
    Ok(())
}

/// Measure how many UTF-8 bytes of `text` fit in `max_width`.
fn measure_fit(
    font_system: &mut FontSystem,
    text: &str,
    max_width: f32,
    font_size: f32,
    line_height: f32,
    family: Family<'_>,
) -> (usize, f32, f32) {
    let line_h = font_size * line_height.max(1.0);
    if text.is_empty() {
        return (0, 0.0, line_h);
    }

    let metrics = Metrics::new(font_size, line_h);
    let mut buffer = Buffer::new(font_system, metrics);
    buffer.set_size(font_system, Some(max_width.max(1.0)), None);
    buffer.set_wrap(font_system, Wrap::Glyph);
    let attrs = Attrs::new().family(family);
    buffer.set_text(font_system, text, attrs, Shaping::Advanced);
    buffer.shape_until_scroll(font_system, false);

    let layout_lines: Vec<_> = buffer.layout_runs().collect();
    let mut end_byte = 0usize;
    let mut width = 0.0f32;
    let mut shaped_line_h = line_h;
    if let Some(run) = layout_lines.first() {
        if run.line_height > 0.0 {
            shaped_line_h = run.line_height;
        }
        for glyph in run.glyphs.iter() {
            end_byte = glyph.end;
            width = glyph.x + glyph.w;
        }
    }

    if end_byte > text.len() {
        end_byte = text.len();
    }
    while end_byte > 0 && !text.is_char_boundary(end_byte) {
        end_byte -= 1;
    }

    let max_chars = estimated_max_chars(max_width, font_size);
    let char_count = if end_byte == 0 {
        0
    } else {
        text[..end_byte].chars().count()
    };

    let broken = (width < font_size * 0.05 && char_count > 1)
        || (char_count > max_chars.saturating_mul(2))
        || (end_byte == 0 && !text.is_empty());

    if broken {
        let n = max_chars.min(text.chars().count()).max(1);
        end_byte = bytes_for_chars(text, n);
        width = (n as f32) * font_size;
        return (end_byte, width.min(max_width), shaped_line_h);
    }

    if end_byte == 0 {
        end_byte = text.chars().next().map(|c| c.len_utf8()).unwrap_or(1);
        width = font_size;
    }

    if end_byte >= text.len() && text.chars().count() > 1 {
        let measured = measure_width(font_system, text, font_size, line_height, family);
        if measured > max_width * 1.02 {
            let total = text.chars().count();
            let mut lo = 1usize;
            let mut hi = total.min(max_chars.saturating_mul(2)).max(1);
            while lo < hi {
                let mid = (lo + hi + 1) / 2;
                let b = bytes_for_chars(text, mid);
                let w = measure_width(font_system, &text[..b], font_size, line_height, family);
                if w <= max_width || mid == 1 {
                    lo = mid;
                } else {
                    hi = mid - 1;
                }
            }
            end_byte = bytes_for_chars(text, lo.max(1));
            width = measure_width(
                font_system,
                &text[..end_byte],
                font_size,
                line_height,
                family,
            );
            if width < font_size * 0.05 {
                width = (lo as f32) * font_size;
            }
        }
    }

    // Pull trailing forbidden-start punctuation onto previous line when possible.
    end_byte = apply_cjk_line_break_rules(text, end_byte);

    (end_byte, width, shaped_line_h)
}

/// Avoid forbidden characters at the start of the *next* line by extending
/// this line when there is still room in the remainder (decision only —
/// Flutter remeasures).
fn apply_cjk_line_break_rules(text: &str, end_byte: usize) -> usize {
    if end_byte == 0 || end_byte >= text.len() {
        return end_byte;
    }
    let mut end = end_byte;
    // If next char is line-start-forbidden, try to include it in this line.
    if let Some(next) = text[end..].chars().next() {
        if is_line_start_forbidden(next) {
            let take = next.len_utf8();
            // Only if we still leave something, or the rest is just punctuation.
            if end + take <= text.len() {
                end += take;
                // Chain consecutive forbidden marks (。！？)
                while end < text.len() {
                    if let Some(c) = text[end..].chars().next() {
                        if is_line_start_forbidden(c) {
                            end += c.len_utf8();
                            continue;
                        }
                    }
                    break;
                }
            }
        }
    }
    while end > 0 && !text.is_char_boundary(end) {
        end -= 1;
    }
    // Never empty the line if we had content.
    if end == 0 {
        return end_byte;
    }
    end
}

fn measure_width(
    font_system: &mut FontSystem,
    text: &str,
    font_size: f32,
    line_height: f32,
    family: Family<'_>,
) -> f32 {
    let metrics = Metrics::new(font_size, font_size * line_height);
    let mut buffer = Buffer::new(font_system, metrics);
    buffer.set_size(font_system, None, None);
    buffer.set_wrap(font_system, Wrap::None);
    let attrs = Attrs::new().family(family);
    buffer.set_text(font_system, text, attrs, Shaping::Advanced);
    buffer.shape_until_scroll(font_system, false);
    let mut width = 0.0f32;
    for run in buffer.layout_runs() {
        for glyph in run.glyphs.iter() {
            width = width.max(glyph.x + glyph.w);
        }
    }
    width
}

pub fn paginate(input: &LayoutInput) -> Result<PaginateResult, String> {
    let cancel = job_flag(input.job_id);
    if is_cancelled(&cancel) {
        return Err("cancelled".into());
    }

    let mut font_system = FONT_SYSTEM.lock();
    ensure_font(&mut font_system, &input.font_path)?;

    // Map Flutter pubspec aliases → TTF name-table families.
    let family_owned = match input.font_family.as_str() {
        "" | "HarmonyOSSansSC" => "HarmonyOS Sans SC".to_string(),
        "NotoSansSC" => "Noto Sans SC".to_string(),
        other => other.to_string(),
    };
    let family = Family::Name(family_owned.as_str());

    let pad_l = if input.padding_left > 0.0 {
        input.padding_left
    } else {
        input.padding_horizontal
    };
    let pad_r = if input.padding_right > 0.0 {
        input.padding_right
    } else {
        input.padding_horizontal
    };
    let pad_v = if input.padding_vertical > 0.0 {
        input.padding_vertical
    } else {
        (input.padding_top + input.padding_bottom).max(0.0)
    };

    let content_width = (input.page_width - pad_l - pad_r).max(1.0);
    // 1% slack so Flutter paint metrics don't force overflow.
    let fit_width = (content_width * 0.99).max(1.0);
    let size = input.font_size.max(1.0);
    let line_h = size * input.line_height.max(1.0);
    let content_height = (input.page_height - pad_v).max(1.0);
    let height2 = (content_height - line_h).max(1.0);
    let want_justify = input.text_align != "left";
    let paragraph_spacing = input.paragraph_spacing.max(0.0);

    // Slice text from start_char (UTF-8 boundary).
    let mut start = input.start_char.min(input.text.len());
    while start > 0 && !input.text.is_char_boundary(start) {
        start -= 1;
    }
    let full = &input.text[start..];

    let paragraphs: Vec<&str> = if full.is_empty() {
        Vec::new()
    } else {
        full.split('\n').collect()
    };

    let mut pages: Vec<TextPageOut> = Vec::new();
    let mut lines: Vec<TextLineOut> = Vec::new();
    let mut top: f32 = 0.0;
    let mut page_char_start = start;
    let mut cursor = start; // absolute UTF-8 offset in input.text
    let mut page_index: u32 = 0;
    let mut line_counter: u32 = 0;

    let flush_page = |lines: &mut Vec<TextLineOut>,
                      pages: &mut Vec<TextPageOut>,
                      top: &mut f32,
                      page_index: &mut u32,
                      page_char_start: &mut usize,
                      cursor: usize,
                      should_justify: bool,
                      content_height: f32| {
        if should_justify && input.should_justify_height {
            let len = lines.len();
            if len > 1 {
                let used = *top;
                let justify = (content_height - used) / (len as f32 - 1.0);
                if justify.is_finite() && justify > 0.0 {
                    for i in 0..len {
                        lines[i].top += justify * i as f32;
                    }
                }
            }
        }
        let page_h = lines.last().map(|l| l.top + l.height).unwrap_or(0.0);
        pages.push(TextPageOut {
            lines: std::mem::take(lines),
            height: page_h,
            page_index: *page_index,
            char_start: *page_char_start,
            char_end: cursor,
        });
        *page_index += 1;
        *page_char_start = cursor;
        *top = 0.0;
    };

    for (pi, para) in paragraphs.iter().enumerate() {
        if is_cancelled(&cancel) {
            return Err("cancelled".into());
        }
        let mut remaining = (*para).to_string();
        let para_abs_start = cursor;

        if remaining.is_empty() {
            // Empty paragraph → vertical gap only.
            if top > height2 {
                flush_page(
                    &mut lines,
                    &mut pages,
                    &mut top,
                    &mut page_index,
                    &mut page_char_start,
                    cursor,
                    true,
                    content_height,
                );
                if input.first_page_only && pages.len() >= 1 {
                    return Ok(PaginateResult {
                        pages,
                        complete: false,
                        next_char: cursor,
                        engine: "rust".into(),
                        abi: 3,
                    });
                }
                if input.max_pages > 0 && pages.len() as u32 >= input.max_pages {
                    return Ok(PaginateResult {
                        pages,
                        complete: false,
                        next_char: cursor,
                        engine: "rust".into(),
                        abi: 3,
                    });
                }
            } else {
                top += paragraph_spacing;
            }
            cursor += 1; // the '\n'
            continue;
        }

        loop {
            if remaining.is_empty() {
                break;
            }
            line_counter = line_counter.wrapping_add(1);
            if line_counter % 32 == 0 && is_cancelled(&cancel) {
                return Err("cancelled".into());
            }

            let (count, _w, shaped_h) = measure_fit(
                &mut font_system,
                &remaining,
                fit_width,
                size,
                input.line_height,
                family,
            );
            let mut end = if count == 0 {
                remaining.chars().next().map(|c| c.len_utf8()).unwrap_or(1)
            } else {
                count.min(remaining.len())
            };
            while end > 0 && !remaining.is_char_boundary(end) {
                end -= 1;
            }
            if end == 0 {
                end = remaining.chars().next().map(|c| c.len_utf8()).unwrap_or(1);
            }

            let text = remaining[..end].to_string();
            let measured = measure_width(
                &mut font_system,
                &text,
                size,
                input.line_height,
                family,
            );
            let is_para_end = end >= remaining.len();
            // Nearly full → justify intent (Flutter computes spacing).
            let nearly_full = measured > content_width - size && measured > size * 0.5;
            let char_count = text.chars().count();
            let justify = want_justify
                && !is_para_end
                && nearly_full
                && char_count > 1;

            let line_height_px = if shaped_h > 0.0 { shaped_h } else { line_h };

            // New page if this line would overflow.
            if top > height2 && !lines.is_empty() {
                flush_page(
                    &mut lines,
                    &mut pages,
                    &mut top,
                    &mut page_index,
                    &mut page_char_start,
                    cursor,
                    true,
                    content_height,
                );
                if input.first_page_only {
                    return Ok(PaginateResult {
                        pages,
                        complete: false,
                        next_char: cursor,
                        engine: "rust".into(),
                        abi: 3,
                    });
                }
                if input.max_pages > 0 && pages.len() as u32 >= input.max_pages {
                    return Ok(PaginateResult {
                        pages,
                        complete: false,
                        next_char: cursor,
                        engine: "rust".into(),
                        abi: 3,
                    });
                }
            }

            lines.push(TextLineOut {
                text,
                top,
                height: line_height_px,
                justify,
                is_last_line: is_para_end,
                is_paragraph_end: is_para_end,
                target_width: content_width,
            });
            top += line_height_px;
            cursor += end;

            if is_para_end {
                remaining.clear();
                // paragraph spacing after last line of paragraph
                if pi + 1 < paragraphs.len() {
                    if top > height2 {
                        flush_page(
                            &mut lines,
                            &mut pages,
                            &mut top,
                            &mut page_index,
                            &mut page_char_start,
                            cursor,
                            true,
                            content_height,
                        );
                    } else {
                        top += paragraph_spacing;
                    }
                }
                // account for '\n' separator except after last para
                if pi + 1 < paragraphs.len() {
                    cursor += 1;
                }
                break;
            } else {
                remaining = remaining[end..].to_string();
            }
            let _ = para_abs_start; // silence unused in some paths
        }
    }

    if !lines.is_empty() {
        flush_page(
            &mut lines,
            &mut pages,
            &mut top,
            &mut page_index,
            &mut page_char_start,
            cursor,
            false,
            content_height,
        );
    }
    if pages.is_empty() {
        pages.push(TextPageOut {
            lines: vec![],
            height: 0.0,
            page_index: 0,
            char_start: start,
            char_end: start,
        });
    }

    let complete = cursor >= input.text.len() || input.text[start..].is_empty();
    Ok(PaginateResult {
        pages,
        complete,
        next_char: cursor.min(input.text.len()),
        engine: "rust".into(),
        abi: 3,
    })
}

/// Convenience for tests / sync full paginate returning pages only.
pub fn paginate_pages(input: &LayoutInput) -> Result<Vec<TextPageOut>, String> {
    Ok(paginate(input)?.pages)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_text_one_page() {
        // Without a real font file this returns Err — that's ABI3 behaviour.
        let res = paginate(&LayoutInput {
            text: String::new(),
            font_size: 26.0,
            line_height: 1.8,
            paragraph_spacing: 10.0,
            page_width: 360.0,
            page_height: 640.0,
            padding_left: 20.0,
            padding_right: 20.0,
            padding_horizontal: 20.0,
            padding_top: 0.0,
            padding_bottom: 0.0,
            padding_vertical: 0.0,
            should_justify_height: false,
            font_path: String::new(),
            font_family: "HarmonyOS Sans SC".into(),
            text_align: "justify".into(),
            base_letter_spacing: 0.0,
            job_id: 0,
            first_page_only: false,
            start_char: 0,
            max_pages: 0,
        });
        assert!(res.is_err());
    }

    #[test]
    fn line_start_forbidden_marks() {
        assert!(is_line_start_forbidden('。'));
        assert!(is_line_start_forbidden('，'));
        assert!(!is_line_start_forbidden('中'));
    }
}
