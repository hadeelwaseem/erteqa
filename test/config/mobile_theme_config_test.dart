import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/bootstrap_config.dart';
import 'package:sooq_merchant/config/config_mode.dart';
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

  test('MobileAppConfig includes theme from render JSON', () {
    const bootstrap = BootstrapConfig(
      schemaVersion: '1.0',
      configMode: ConfigMode.local,
      variantId: 'test',
      appName: 'Test',
      bundleId: 'x',
      apiBaseUrl: 'https://x',
    );
    final config = MobileAppConfig.fromBootstrapAndRender(
      bootstrap: bootstrap,
      renderJson: {
        'schemaVersion': '1.0',
        'theme': {
          'colors': {'primary': '#1D4ED8', 'text': '#0F172A'},
          'typography': {'fontFamily': 'Tajawal'},
          'buttons': {'md': {'radius': 12}},
        },
        'navigation': {'type': 'tabs', 'initialRoute': '/', 'tabs': []},
        'pages': [],
      },
    );

    expect(config.theme.typography.fontFamily, 'Tajawal');
    expect(config.theme.buttons.md.radius, 12);
  });
}
