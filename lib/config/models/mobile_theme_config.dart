/// Theme block parsed from mobile JSON config (`theme` key).
/// Flutter-free — colors stored as hex strings.
class MobileThemeConfig {
  final String mode;
  final ThemeColors colors;
  final ThemeTypography typography;
  final Map<String, double> radius;
  final Map<String, double> spacing;
  final ThemeButtons buttons;

  const MobileThemeConfig({
    required this.mode,
    required this.colors,
    required this.typography,
    required this.radius,
    required this.spacing,
    required this.buttons,
  });

  factory MobileThemeConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return MobileThemeConfig.defaults();
    }
    return MobileThemeConfig(
      mode: json['mode'] as String? ?? 'light',
      colors: ThemeColors.fromJson(
        json['colors'] as Map<String, dynamic>?,
      ),
      typography: ThemeTypography.fromJson(
        json['typography'] as Map<String, dynamic>?,
      ),
      radius: _parseDoubleMap(json['radius']),
      spacing: _parseDoubleMap(json['spacing']),
      buttons: ThemeButtons.fromJson(
        json['buttons'] as Map<String, dynamic>?,
      ),
    );
  }

  factory MobileThemeConfig.defaults() => MobileThemeConfig(
        mode: 'light',
        colors: ThemeColors.defaults(),
        typography: ThemeTypography.defaults(),
        radius: const {
          'none': 0,
          'sm': 6,
          'md': 10,
          'lg': 14,
          'xl': 20,
          'full': 9999,
        },
        spacing: const {
          'xs': 4,
          'sm': 10,
          'md': 16,
          'lg': 24,
          'xl': 36,
        },
        buttons: ThemeButtons.defaults(),
      );

  double typographyScale(String key) =>
      typography.scale[key] ?? typography.scale['md'] ?? 16;

  double radiusValue(String key) => radius[key] ?? radius['md'] ?? 10;

  /// Parses `#RRGGBB` or `#AARRGGBB` to `0xAARRGGBB` int, or null on failure.
  static int? parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var normalized = hex.trim();
    if (!normalized.startsWith('#')) return null;
    normalized = normalized.substring(1);
    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    } else if (normalized.length != 8) {
      return null;
    }
    try {
      return int.parse(normalized, radix: 16);
    } catch (_) {
      return null;
    }
  }

  static Map<String, double> _parseDoubleMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num?)?.toDouble() ?? 0,
      ),
    );
  }
}

class ThemeColors {
  final String primary;
  final String surface;
  final String background;
  final String text;
  final String muted;
  final String success;
  final String warning;
  final String error;

  const ThemeColors({
    required this.primary,
    required this.surface,
    required this.background,
    required this.text,
    required this.muted,
    required this.success,
    required this.warning,
    required this.error,
  });

  factory ThemeColors.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return ThemeColors.defaults();
    return ThemeColors(
      primary: json['primary'] as String? ?? '#1D4ED8',
      surface: json['surface'] as String? ?? '#F8FAFC',
      background: json['background'] as String? ?? '#F1F5F9',
      text: json['text'] as String? ?? '#0F172A',
      muted: json['muted'] as String? ?? '#475569',
      success: json['success'] as String? ?? '#16A34A',
      warning: json['warning'] as String? ?? '#D97706',
      error: json['error'] as String? ?? '#DC2626',
    );
  }

  factory ThemeColors.defaults() => const ThemeColors(
        primary: '#1D4ED8',
        surface: '#F8FAFC',
        background: '#F1F5F9',
        text: '#0F172A',
        muted: '#475569',
        success: '#16A34A',
        warning: '#D97706',
        error: '#DC2626',
      );
}

class ThemeTypography {
  final String fontFamily;
  final Map<String, double> scale;
  final Map<String, int> weights;
  final Map<String, double> lineHeight;

  const ThemeTypography({
    required this.fontFamily,
    required this.scale,
    required this.weights,
    required this.lineHeight,
  });

  factory ThemeTypography.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return ThemeTypography.defaults();
    return ThemeTypography(
      fontFamily: json['fontFamily'] as String? ?? 'Tajawal',
      scale: MobileThemeConfig._parseDoubleMap(json['scale']),
      weights: _parseIntMap(json['weights']),
      lineHeight: MobileThemeConfig._parseDoubleMap(json['lineHeight']),
    );
  }

  factory ThemeTypography.defaults() => const ThemeTypography(
        fontFamily: 'Tajawal',
        scale: {
          'xs': 12,
          'sm': 13,
          'md': 16,
          'lg': 18,
          'xl': 22,
          'xxl': 28,
          'display': 36,
        },
        weights: {
          'normal': 400,
          'medium': 500,
          'bold': 700,
        },
        lineHeight: {
          'tight': 1.25,
          'normal': 1.5,
          'relaxed': 1.75,
        },
      );

  static Map<String, int> _parseIntMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num?)?.toInt() ?? 0,
      ),
    );
  }
}

class ThemeButtons {
  final ThemeButtonSize sm;
  final ThemeButtonSize md;
  final ThemeButtonSize lg;

  const ThemeButtons({
    required this.sm,
    required this.md,
    required this.lg,
  });

  factory ThemeButtons.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return ThemeButtons.defaults();
    return ThemeButtons(
      sm: ThemeButtonSize.fromJson(json['sm'] as Map<String, dynamic>?),
      md: ThemeButtonSize.fromJson(json['md'] as Map<String, dynamic>?),
      lg: ThemeButtonSize.fromJson(json['lg'] as Map<String, dynamic>?),
    );
  }

  factory ThemeButtons.defaults() => ThemeButtons(
        sm: ThemeButtonSize.defaults(
          height: 36,
          padX: 14,
          fontSize: 14,
          radius: 10,
        ),
        md: ThemeButtonSize.defaults(
          height: 48,
          padX: 18,
          fontSize: 16,
          radius: 12,
        ),
        lg: ThemeButtonSize.defaults(
          height: 56,
          padX: 26,
          fontSize: 16,
          radius: 14,
        ),
      );
}

class ThemeButtonSize {
  final double height;
  final double padX;
  final double fontSize;
  final double radius;

  const ThemeButtonSize({
    required this.height,
    required this.padX,
    required this.fontSize,
    required this.radius,
  });

  factory ThemeButtonSize.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return ThemeButtonSize.defaults();
    }
    return ThemeButtonSize(
      height: (json['height'] as num?)?.toDouble() ?? 48,
      padX: (json['padX'] as num?)?.toDouble() ?? 18,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      radius: (json['radius'] as num?)?.toDouble() ?? 12,
    );
  }

  factory ThemeButtonSize.defaults({
    double height = 48,
    double padX = 18,
    double fontSize = 16,
    double radius = 12,
  }) =>
      ThemeButtonSize(
        height: height,
        padX: padX,
        fontSize: fontSize,
        radius: radius,
      );
}
