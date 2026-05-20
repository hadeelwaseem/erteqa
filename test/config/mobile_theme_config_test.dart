import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/config/models/mobile_theme_config.dart';

void main() {
  group('MobileThemeConfig', () {
    test('parses production theme block shape', () {
      final theme = MobileThemeConfig.fromJson({
        'mode': 'light',
        'colors': {
          'primary': '#1D4ED8',
          'surface': '#F8FAFC',
          'background': '#F1F5F9',
          'text': '#0F172A',
          'muted': '#475569',
          'success': '#16A34A',
          'warning': '#D97706',
          'error': '#DC2626',
        },
        'typography': {
          'fontFamily': 'Tajawal',
          'scale': {'md': 16},
        },
        'buttons': {
          'md': {
            'height': 48,
            'padX': 18,
            'fontSize': 16,
            'radius': 12,
          },
        },
      });

      expect(theme.colors.primary, '#1D4ED8');
      expect(theme.typography.fontFamily, 'Tajawal');
      expect(theme.buttons.md.radius, 12);
      expect(theme.typographyScale('md'), 16);
    });

    test('defaults when theme json is null', () {
      final theme = MobileThemeConfig.fromJson(null);
      expect(theme.colors.primary, '#1D4ED8');
      expect(theme.buttons.md.radius, 12);
    });

    test('parseHexColor handles six-digit hex', () {
      expect(
        MobileThemeConfig.parseHexColor('#0F172A'),
        0xFF0F172A,
      );
    });
  });

  test('MobileAppConfig includes theme from json', () {
    final config = MobileAppConfig.fromJson(
      {
        'schemaVersion': '1.0',
        'app': {'name': 'Test', 'bundleId': 'x', 'apiBaseUrl': 'https://x'},
        'theme': {
          'colors': {'primary': '#1D4ED8', 'text': '#0F172A'},
          'typography': {'fontFamily': 'Tajawal'},
          'buttons': {'md': {'radius': 12}},
        },
        'navigation': {'type': 'tabs', 'initialRoute': '/', 'tabs': []},
        'pages': [],
      },
      'test',
    );

    expect(config.theme.typography.fontFamily, 'Tajawal');
    expect(config.theme.buttons.md.radius, 12);
  });
}
