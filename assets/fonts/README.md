# Reader fonts (ABI v3)

Place a CJK TTF/OTF here as:

    NotoSansSC-Regular.ttf

Flutter paints with family `NotoSansSC` (see pubspec.yaml).
At startup, `ReaderFontBootstrap` copies this file into app support so
Rust `book_pager` loads the **same** bytes via `load_font_file`.

Without this file:
- Flutter still runs (platform font / custom user font)
- Rust native pager falls back to Dart TextComposition when `font_path` is empty

Suggested source: Noto Sans SC (SIL OFL) from Google Fonts / notofonts/noto-cjk.
