/// Shared constants (prefs keys).
class Common {
  static String bgIdx = PrefsKeys.bgIdx;
  static String turnPageAnima = PrefsKeys.pageTurnMode;

  static String book_search_history = PrefsKeys.bookSearchHistory;
  static String reading_style = PrefsKeys.readingStyle;
  static String fonts = PrefsKeys.fonts;
  static String book_pic_width = PrefsKeys.bookPicWidth;
  static String top_safe_height = PrefsKeys.topSafeHeight;
  static String shimmer_nums = PrefsKeys.shimmerNums;
  static String source_disclaimer_agreed = PrefsKeys.sourceDisclaimerAgreed;
}

/// Canonical SpUtil key strings used across the app.
///
/// Prefer these over string literals so prefs stay discoverable.
class PrefsKeys {
  PrefsKeys._();

  static const dark = 'dark';
  static const auth = 'auth';
  static const token = 'token';
  static const username = 'username';
  static const email = 'email';
  static const version = 'version';
  static const coverGrid = 'cover';
  static const leftClickNext = 'leftClickNext';
  static const bgIdx = 'bgIdx';
  static const pageTurnMode = 'turnPageAnima';
  static const bookSearchHistory = 'book_search_history';
  static const readingStyle = 'READINGSTYLE';
  static const fonts = 'fonts';
  static const bookPicWidth = 'book_pic_width';
  static const topSafeHeight = 'top_safe_height';
  static const shimmerNums = 'shimmer_nums';
  static const sourceDisclaimerAgreed = 'source_disclaimer_agreed';
}
