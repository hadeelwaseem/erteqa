import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sooq_merchant/config/models/mobile_theme_config.dart';

/// Runtime theme bridge for JSON `theme` — injected into engine [dataContext].
class EngineTheme {
  static const contextKey = '_engineTheme';

  final MobileThemeConfig config;

  const EngineTheme(this.config);

  factory EngineTheme.fromConfig(MobileThemeConfig config) =>
      EngineTheme(config);

  static EngineTheme? fromDataContext(Map<String, dynamic>? dataContext) {
    final value = dataContext?[contextKey];
    return value is EngineTheme ? value : null;
  }

  ThemeButtonSize get buttonMd => config.buttons.md;

  Color? _colorFromHex(String hex) {
    final argb = MobileThemeConfig.parseHexColor(hex);
    return argb != null ? Color(argb) : null;
  }

  Color get textColor => _colorFromHex(config.colors.text) ?? const Color(0xFF0F172A);

  Color get primaryColor =>
      _colorFromHex(config.colors.primary) ?? const Color(0xFF1D4ED8);

  Color get surfaceColor =>
      _colorFromHex(config.colors.surface) ?? const Color(0xFFF8FAFC);

  Color get backgroundColor =>
      _colorFromHex(config.colors.background) ?? const Color(0xFFF1F5F9);

  Color get errorColor =>
      _colorFromHex(config.colors.error) ?? const Color(0xFFDC2626);

  double typographyScale(String key) => config.typographyScale(key);

  /// Builds [ThemeData] for [MaterialApp] from parsed JSON theme.
  static ThemeData toThemeData(MobileThemeConfig config) {
    final engine = EngineTheme(config);
    final primary = engine.primaryColor;
    final surface = engine.surfaceColor;
    final background = engine.backgroundColor;
    final error = engine.errorColor;
    final onPrimary = _contrastOn(primary);
    final onSurface = engine.textColor;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );

    final family = config.typography.fontFamily.trim().toLowerCase();
    if (family == 'tajawal') {
      try {
        return base.copyWith(
          textTheme: GoogleFonts.tajawalTextTheme(base.textTheme),
          primaryTextTheme: GoogleFonts.tajawalTextTheme(base.primaryTextTheme),
        );
      } catch (_) {
        // Offline / test / font fetch failure — fall back to family name.
      }
    }

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: config.typography.fontFamily,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: config.typography.fontFamily,
      ),
    );
  }

  static Color _contrastOn(Color background) {
    return background.computeLuminance() > 0.5
        ? const Color(0xFF0F172A)
        : Colors.white;
  }
}
