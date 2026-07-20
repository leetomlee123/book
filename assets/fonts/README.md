# Reader fonts (ABI v3)

## Bundled default

| File | Flutter family (`pubspec`) | TTF name table | Role |
|------|----------------------------|----------------|------|
| `HarmonyOS_Sans_SC_Regular.ttf` | `HarmonyOSSansSC` | `HarmonyOS Sans SC` | Default CJK body (~7.9 MB) |
| `HarmonyOS_Sans_SC_LICENSE.txt` | — | — | Upstream license |

Flutter paints with family `HarmonyOSSansSC`.  
At startup, `ReaderFontBootstrap` copies the TTF into app support so  
Rust `book_pager` loads the **same** bytes via `load_font_file` (family  
hint mapped to `HarmonyOS Sans SC`).

### Why this file

From the HarmonyOS Sans package we only ship **Simplified Chinese Regular**:

- `HarmonyOS_Sans_SC_Regular.ttf` — full SC CJK, good for long-form reading  
- Latin-only `HarmonyOS_Sans_*.ttf` (~140 KB) — **no** Chinese → not used  
- Condensed / Italic / Arabic / TC — not needed for default mainland reading  

Optional later: Medium/Bold for UI chrome only (not body pagination).

Without this file:

- Flutter still runs (platform font / user-selected download)
- Rust native pager falls back to Dart when `font_path` is empty
