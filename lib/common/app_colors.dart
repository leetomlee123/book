import 'package:flutter/material.dart';

/// WeChat Reading–inspired design tokens.
///
/// App chrome (Material) should read these via [ColorModel] / ThemeData.
/// Reader canvas ([ReadModel.drawContent]) must use paper tokens from
/// [ReadSetting] / these constants — **not** `Theme.of(context)`.
class AppColors {
  AppColors._();

  // Brand (WeRead default green). Prefer [accentOf] / [accentSoftOf] in chrome
  // UI so FlexColorScheme skins follow the active theme primary.
  static const Color brand = Color(0xFF1AAD19);
  static const Color brandPressed = Color(0xFF179B16);
  static const Color brandSoft = Color(0x1A1AAD19); // ~10% alpha

  /// Active theme accent (skin / WeRead primary).
  static Color accentOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Soft fill of the active accent (~10% alpha by default).
  static Color accentSoftOf(BuildContext context, {double alpha = 0.10}) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: alpha);

  // Surfaces
  static const Color scaffold = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEDEDED);
  static const Color cardBorder = Color(0xFFF0F0F0);

  // Text
  static const Color textPrimary = Color(0xFF191919);
  static const Color textSecondary = Color(0xFF8C8C8C);
  static const Color textTertiary = Color(0xFFB2B2B2);
  static const Color textOnBrand = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE8E8E8);

  // Semantic
  static const Color danger = Color(0xFFFA5151);
  static const Color updateBadge = Color(0xFFFA5151);

  // Reader paper (product defaults)
  static const Color paperWhite = Color(0xFFFFFFFF);
  static const Color paperCream = Color(0xFFF5F1E8);
  static const Color paperGreen = Color(0xFFCCE8CF);
  static const Color paperNight = Color(0xFF111111);

  static const Color inkOnLight = Color(0xFF2C2C2C);
  static const Color inkOnGreen = Color(0xFF1F3A24);
  static const Color inkOnNight = Color(0xB3FFFFFF); // ~70% white

  // Dark chrome
  static const Color scaffoldDark = Color(0xFF111111);
  static const Color surfaceDark = Color(0xFF1C1C1C);
  static const Color dividerDark = Color(0xFF2A2A2A);
}

class AppDimens {
  AppDimens._();

  static const double pagePadding = 16;
  static const double coverRadius = 6;
  static const double cardRadius = 10;
  static const double searchBarHeight = 36;
  static const double ctaHeight = 44;
  static const double coverAspect = 0.72; // width / height
  static const int shelfColumns = 3;
  static const double shelfSpacing = 14;
  static const double shelfRunSpacing = 18;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> cover = [
    BoxShadow(
      color: const Color(0x1A000000),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> softBar = [
    BoxShadow(
      color: const Color(0x0D000000),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];
}

/// Builds a neutral WeChat-like ThemeData (white surface + brand green).
ThemeData buildWeReadTheme({
  required bool dark,
  String? fontFamily,
  Color? accent,
}) {
  final primary = accent ?? AppColors.brand;
  final base = dark
      ? ColorScheme.dark(
          primary: primary,
          secondary: primary,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textOnDark,
          error: AppColors.danger,
        )
      : ColorScheme.light(
          primary: primary,
          secondary: primary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.danger,
        );

  final scaffold = dark ? AppColors.scaffoldDark : AppColors.scaffold;
  final onSurface = dark ? AppColors.textOnDark : AppColors.textPrimary;

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: base,
    primaryColor: primary,
    scaffoldBackgroundColor: scaffold,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: dark ? AppColors.surfaceDark : AppColors.surface,
      foregroundColor: onSurface,
      iconTheme: IconThemeData(color: onSurface),
      titleTextStyle: TextStyle(
        color: onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: dark ? AppColors.surfaceDark : AppColors.surface,
      selectedItemColor: primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
    ),
    dividerColor: dark ? AppColors.dividerDark : AppColors.divider,
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: AppColors.textOnBrand,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.textOnBrand,
        elevation: 0,
        minimumSize: const Size(0, AppDimens.ctaHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      thumbColor: primary,
      inactiveTrackColor: primary.withValues(alpha: 0.2),
      overlayColor: primary.withValues(alpha: 0.12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return primary;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.45);
        }
        return null;
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? AppColors.surfaceDark : AppColors.scaffold,
      selectedColor: primary.withValues(alpha: 0.10),
      checkmarkColor: primary,
      labelStyle: TextStyle(
        color: onSurface,
        fontSize: 13,
        fontFamily: fontFamily,
      ),
      secondaryLabelStyle: TextStyle(
        color: primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: dark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
    ),
  );
}
