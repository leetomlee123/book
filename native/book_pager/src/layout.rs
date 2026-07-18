//! Core pagination algorithm — port of `lib/common/text_composition.dart`.
//!
//! Layout rules (matching the Dart implementation):
//! - Split content by `\n` into paragraphs
//! - Soft-wrap each paragraph to `column_width` using font metrics
//! - Full-justify letter-spacing when a line is near full width
//! - Paginate when next line would exceed content height
//! - Optionally redistribute vertical space (bottom justify) per page

use cosmic_text::{Attrs, Buffer, Family, FontSystem, Metrics, Shaping, Wrap};
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Shared font system — `FontSystem::new()` scans system fonts and is expensive.
/// On Android, fontdb's `load_system_fonts` is a no-op, so we also load
/// `/system/fonts` (and a few product paths) once.
static FONT_SYSTEM: Lazy<Mutex<FontSystem>> = Lazy::new(|| {
    let mut fs = FontSystem::new();
    load_platform_fonts(fs.db_mut());
    // Prefer a CJK-capable default family when present on Android devices.
    prefer_cjk_defaults(fs.db_mut());
    Mutex::new(fs)
});

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutInput {
    /// Full chapter text (paragraphs separated by `\n`)
    pub text: String,
    pub font_size: f32,
    /// Multiplier of font size for line height (matches Flutter TextStyle.height)
    pub line_height: f32,
    /// Extra gap after a paragraph ends (already scaled by caller if needed)
    pub paragraph: f32,
    pub box_width: f32,
    pub box_height: f32,
    pub padding_horizontal: f32,
    pub padding_vertical: f32,
    pub should_justify_height: bool,
    /// Optional absolute path to a TTF/OTF font file. Empty = system default.
    pub font_path: String,
    /// CSS-like family name hint (used when loading from system / font_path)
    pub font_family: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextLineOut {
    pub text: String,
    pub dx: f32,
    pub dy: f32,
    pub letter_spacing: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TextPageOut {
    pub lines: Vec<TextLineOut>,
    pub height: f32,
}

/// fontdb does not load fonts on Android (`target_os = "android"` is excluded
/// from its unix branch). Without any faces, cosmic-text panics with
/// `no default font found` — which aborts the whole Flutter process across FFI.
fn load_platform_fonts(db: &mut fontdb::Database) {
    #[cfg(target_os = "android")]
    {
        const DIRS: &[&str] = &[
            "/system/fonts",
            "/system/font",
            "/system/product/fonts",
            "/product/fonts",
            "/system/product/fonts/google",
            "/data/fonts",
        ];
        for dir in DIRS {
            if Path::new(dir).is_dir() {
                db.load_fonts_dir(dir);
            }
        }
    }

    // Also try common paths on other Unix targets when system scan found nothing.
    #[cfg(all(unix, not(target_os = "android"), not(target_os = "macos")))]
    {
        if db.is_empty() {
            for dir in ["/usr/share/fonts", "/usr/local/share/fonts"] {
                if Path::new(dir).is_dir() {
                    db.load_fonts_dir(dir);
                }
            }
        }
    }

    let _ = db;
}

fn prefer_cjk_defaults(db: &mut fontdb::Database) {
    // Pick the first family that actually exists in the database.
    const CANDIDATES: &[&str] = &[
        "Noto Sans CJK SC",
        "Noto Sans CJK",
        "Noto Sans SC",
        "Source Han Sans SC",
        "Source Han Sans CN",
        "DroidSansFallback",
        "Droid Sans Fallback",
        "Roboto",
        "Noto Sans",
        "sans-serif",
    ];
    for name in CANDIDATES {
        let found = db.faces().any(|face| {
            face.families
                .iter()
                .any(|(family, _)| family.eq_ignore_ascii_case(name))
        });
        if found {
            db.set_sans_serif_family(*name);
            return;
        }
    }
    // Fallbacks often used as file-name-based families on Android.
    // Even if family match fails, having faces loaded is enough for cosmic-text
    // to pick *some* default; panic only happens when db is empty.
}

/// Max chars that can fit in [max_width] assuming ~1em CJK advance.
fn estimated_max_chars(max_width: f32, font_size: f32) -> usize {
    let em = font_size.max(1.0);
    ((max_width / em).floor() as usize).max(1)
}

/// Byte offset after taking [n] Unicode scalars from [text].
fn bytes_for_chars(text: &str, n: usize) -> usize {
    text.chars().take(n).map(|c| c.len_utf8()).sum()
}

/// Measure how many UTF-8 bytes of `text` fit in `max_width` at the given style.
///
/// Hardened for Android/CJK: when the font has missing glyphs (0-width) or
/// cosmic-text returns the whole paragraph as one run, fall back to em-based
/// char truncation so we never emit a single TextLine longer than one visual row.
fn measure_fit(
    font_system: &mut FontSystem,
    text: &str,
    max_width: f32,
    font_size: f32,
    line_height: f32,
    family: Family<'_>,
) -> (usize, f32, f32) {
    // Returns (byte_count, measured_width, line_height_px)
    let line_h = font_size * line_height.max(1.0);
    if text.is_empty() {
        return (0, 0.0, line_h);
    }

    let metrics = Metrics::new(font_size, line_h);
    let mut buffer = Buffer::new(font_system, metrics);
    buffer.set_size(font_system, Some(max_width.max(1.0)), None);
    buffer.set_wrap(font_system, Wrap::WordOrGlyph);
    let attrs = Attrs::new().family(family);
    buffer.set_text(font_system, text, attrs, Shaping::Advanced);
    buffer.shape_until_scroll(font_system, false);

    // First layout line only — we re-feed remaining text each iteration
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

    // Missing-glyph / broken shape: zero width but claimed many chars, or
    // entire remaining paragraph as one "line" far beyond column capacity.
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

    // Full remainder claimed but still wider than column → force char wrap.
    if end_byte >= text.len() && text.chars().count() > 1 {
        let measured = measure_width(font_system, text, font_size, line_height, family);
        if measured > max_width * 1.02 {
            // Binary search largest char count that fits.
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

    (end_byte, width, shaped_line_h)
}

/// Measure width of an exact string (no wrap).
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

pub fn paginate(input: &LayoutInput) -> Result<Vec<TextPageOut>, String> {
    let mut font_system = FONT_SYSTEM.lock();

    // Load optional custom font (reader download path).
    if !input.font_path.is_empty() {
        if let Err(e) = font_system.db_mut().load_font_file(&input.font_path) {
            eprintln!("book_pager: failed to load font {}: {e}", input.font_path);
        }
    }

    if font_system.db().is_empty() {
        return Err(
            "no fonts available (Android: /system/fonts missing or empty)".into(),
        );
    }

    let family_owned = input.font_family.clone();
    let family = if family_owned.is_empty() || family_owned == "Roboto" {
        Family::SansSerif
    } else {
        Family::Name(family_owned.as_str())
    };

    let column_width = (input.box_width - input.padding_horizontal * 2.0).max(1.0);
    let size = input.font_size.max(1.0);
    let _dx = input.padding_horizontal;
    let _dy = input.padding_vertical;
    let _width = column_width;
    let _width2 = (_width - size).max(1.0);
    let _height = (input.box_height - input.padding_vertical * 2.0).max(1.0);
    let _height2 = (_height - size * input.line_height).max(1.0);

    let paragraphs: Vec<&str> = if input.text.is_empty() {
        Vec::new()
    } else {
        input.text.split('\n').collect()
    };

    let mut pages: Vec<TextPageOut> = Vec::new();
    let mut lines: Vec<TextLineOut> = Vec::new();
    let mut dx = _dx;
    let mut dy = _dy;
    let mut start_line: usize = 0;

    let new_page = |lines: &mut Vec<TextLineOut>,
                    pages: &mut Vec<TextPageOut>,
                    dy: &mut f32,
                    dx: &mut f32,
                    start_line: &mut usize,
                    should_justify: bool,
                    last_page: bool| {
        if should_justify && input.should_justify_height {
            let len = lines.len() - *start_line;
            if len > 1 {
                let justify = (_height - *dy) / (len as f32 - 1.0);
                for i in 0..len {
                    lines[*start_line + i].dy += justify * i as f32;
                }
            }
        }
        if last_page || true {
            // single column only (matches current app usage)
            let page_h = *dy;
            pages.push(TextPageOut {
                lines: std::mem::take(lines),
                height: page_h,
            });
            *dx = _dx;
        }
        *dy = _dy;
        *start_line = lines.len();
    };

    let new_paragraph = |lines: &mut Vec<TextLineOut>,
                         pages: &mut Vec<TextPageOut>,
                         dy: &mut f32,
                         dx: &mut f32,
                         start_line: &mut usize| {
        if *dy > _height2 {
            new_page(lines, pages, dy, dx, start_line, true, false);
        } else {
            *dy += input.paragraph;
        }
    };

    for para in paragraphs {
        let mut remaining = para.to_string();
        loop {
            if remaining.is_empty() {
                new_paragraph(&mut lines, &mut pages, &mut dy, &mut dx, &mut start_line);
                break;
            }
            let (count, _w, line_h) = measure_fit(
                &mut font_system,
                &remaining,
                column_width,
                size,
                input.line_height,
                family,
            );
            let count = if count == 0 {
                remaining.chars().next().map(|c| c.len_utf8()).unwrap_or(1)
            } else {
                count.min(remaining.len())
            };
            // char boundary
            let mut end = count;
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
            let mut spacing = 0.0f32;
            // full-justify when nearly full (matches Dart: tp.width > _width2).
            // Skip when measured is nonsense (missing glyphs → 0 width).
            if measured > _width2 && measured > size * 0.5 && end > 0 {
                let text_count = text.chars().count().max(1) as f32;
                spacing = (_width - measured) / (text_count + 1.0);
                // Clamp pathological spacing from bad metrics.
                if !spacing.is_finite() || spacing.abs() > size {
                    spacing = 0.0;
                }
            }
            lines.push(TextLineOut {
                text,
                dx,
                dy,
                letter_spacing: spacing,
            });
            dy += line_h;
            if end >= remaining.len() {
                remaining.clear();
                new_paragraph(&mut lines, &mut pages, &mut dy, &mut dx, &mut start_line);
                break;
            } else {
                remaining = remaining[end..].to_string();
                if dy > _height2 {
                    new_page(&mut lines, &mut pages, &mut dy, &mut dx, &mut start_line, true, false);
                }
            }
        }
    }

    if !lines.is_empty() {
        new_page(&mut lines, &mut pages, &mut dy, &mut dx, &mut start_line, false, true);
    }
    if pages.is_empty() {
        pages.push(TextPageOut {
            lines: vec![],
            height: 0.0,
        });
    }
    Ok(pages)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_text_one_page() {
        let pages = paginate(&LayoutInput {
            text: String::new(),
            font_size: 26.0,
            line_height: 1.8,
            paragraph: 10.0,
            box_width: 360.0,
            box_height: 640.0,
            padding_horizontal: 20.0,
            padding_vertical: 0.0,
            should_justify_height: true,
            font_path: String::new(),
            font_family: "Roboto".into(),
        })
        .expect("paginate");
        assert_eq!(pages.len(), 1);
        assert!(pages[0].lines.is_empty());
    }

    #[test]
    fn simple_chinese_paginates() {
        let text = "这是一段用于测试分页的中文内容。".repeat(80);
        let pages = paginate(&LayoutInput {
            text,
            font_size: 26.0,
            line_height: 1.8,
            paragraph: 20.0,
            box_width: 360.0,
            box_height: 640.0,
            padding_horizontal: 20.0,
            padding_vertical: 0.0,
            should_justify_height: true,
            font_path: String::new(),
            font_family: "Roboto".into(),
        })
        .expect("paginate");
        assert!(pages.len() >= 1);
        assert!(!pages[0].lines.is_empty());
        // Must soft-wrap: first visual line cannot be the entire chapter.
        assert!(
            pages[0].lines.len() > 1 || pages.len() > 1,
            "expected multi-line or multi-page pagination"
        );
        let first = &pages[0].lines[0].text;
        assert!(
            first.chars().count() < 80,
            "first line too long ({} chars): possible missing wrap",
            first.chars().count()
        );
    }

    #[test]
    fn long_paragraph_wraps_to_many_lines() {
        // Single paragraph without newlines — classic "only first line" repro.
        let text = "山不在高有仙则名水不在深有龙则灵斯是陋室惟吾德馨苔痕上阶绿草色入帘青谈笑有鸿儒往来无白丁可以调素琴阅金经无丝竹之乱耳无案牍之劳形南阳诸葛庐西蜀子云亭孔子云何陋之有".repeat(10);
        let pages = paginate(&LayoutInput {
            text: text.clone(),
            font_size: 19.0,
            line_height: 1.7,
            paragraph: 10.0,
            box_width: 360.0,
            box_height: 640.0,
            padding_horizontal: 20.0,
            padding_vertical: 0.0,
            should_justify_height: true,
            font_path: String::new(),
            font_family: "Roboto".into(),
        })
        .expect("paginate");
        let total_lines: usize = pages.iter().map(|p| p.lines.len()).sum();
        assert!(total_lines > 5, "expected many lines, got {total_lines}");
        for p in &pages {
            for line in &p.lines {
                assert!(
                    line.text.chars().count() <= 40,
                    "line too long: {} chars",
                    line.text.chars().count()
                );
            }
        }
    }
}
