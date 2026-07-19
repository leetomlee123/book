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

/// Backward-compatible alias — prefer [PrefsKeys].
@Deprecated('Use PrefsKeys')
typedef Common = PrefsKeys;
