import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/models/mobile_theme_config.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';
import 'package:sooq_merchant/engine/theme/shadow_parser.dart';
import 'package:sooq_merchant/engine/theme/shadow_tokens.dart';

void main() {
  group('ShadowParser.parseBoxShadowPreset', () {
    test('sm returns ShadowTokens.sm', () {
      expect(
        ShadowParser.parseBoxShadowPreset('sm'),
        ShadowTokens.sm,
      );
    });

    test('md returns ShadowTokens.md', () {
      expect(
        ShadowParser.parseBoxShadowPreset('md'),
        ShadowTokens.md,
      );
    });

    test('lg returns ShadowTokens.lg', () {
      expect(
        ShadowParser.parseBoxShadowPreset('lg'),
        ShadowTokens.lg,
      );
    });

    test('xl returns ShadowTokens.xl', () {
      expect(
        ShadowParser.parseBoxShadowPreset('xl'),
        ShadowTokens.xl,
      );
    });

    test('none returns null', () {
      expect(ShadowParser.parseBoxShadowPreset('none'), isNull);
    });

    test('null returns null', () {
      expect(ShadowParser.parseBoxShadowPreset(null), isNull);
    });

    test('unknown string returns null', () {
      expect(ShadowParser.parseBoxShadowPreset('foo'), isNull);
    });

    test('non-string value returns null', () {
      expect(ShadowParser.parseBoxShadowPreset(123), isNull);
    });
  });

  group('ShadowParser.materialElevationForPreset', () {
    test('none returns 0', () {
      expect(ShadowParser.materialElevationForPreset('none'), 0);
    });

    test('null returns 0', () {
      expect(ShadowParser.materialElevationForPreset(null), 0);
    });

    test('sm returns 1', () {
      expect(ShadowParser.materialElevationForPreset('sm'), 1);
    });

    test('md returns 2', () {
      expect(ShadowParser.materialElevationForPreset('md'), 2);
    });

    test('lg returns 4', () {
      expect(ShadowParser.materialElevationForPreset('lg'), 4);
    });

    test('xl returns 8', () {
      expect(ShadowParser.materialElevationForPreset('xl'), 8);
    });

    test('unknown returns null', () {
      expect(ShadowParser.materialElevationForPreset('foo'), isNull);
    });
  });

  group('ShadowParser.resolveBoxShadowPreset', () {
    test('uses explicit shadow prop over theme default', () {
      final theme = EngineTheme.fromConfig(
        MobileThemeConfig(
          mode: 'light',
          colors: ThemeColors.defaults(),
          typography: ThemeTypography.defaults(),
          radius: const {'md': 10},
          spacing: const {'md': 16},
          buttons: ThemeButtons.defaults(),
          defaultShadows: ThemeDefaultShadows.fromJson(
            const {'container': 'sm'},
          ),
        ),
      );
      final dataContext = {EngineTheme.contextKey: theme};

      expect(
        ShadowParser.resolveBoxShadowPreset(
          {'shadow': 'lg'},
          dataContext,
          componentType: 'container',
        ),
        ShadowTokens.lg,
      );
    });

    test('falls back to theme default when shadow prop omitted', () {
      final theme = EngineTheme.fromConfig(
        MobileThemeConfig(
          mode: 'light',
          colors: ThemeColors.defaults(),
          typography: ThemeTypography.defaults(),
          radius: const {'md': 10},
          spacing: const {'md': 16},
          buttons: ThemeButtons.defaults(),
          defaultShadows: ThemeDefaultShadows.fromJson(
            const {'container': 'sm'},
          ),
        ),
      );
      final dataContext = {EngineTheme.contextKey: theme};

      expect(
        ShadowParser.resolveBoxShadowPreset(
          {},
          dataContext,
          componentType: 'container',
        ),
        ShadowTokens.sm,
      );
    });

    test('returns null when prop and theme default absent', () {
      expect(
        ShadowParser.resolveBoxShadowPreset(
          {},
          null,
          componentType: 'container',
        ),
        isNull,
      );
    });
  });

  group('ShadowTokens preset values (production)', () {
    test('sm has expected blur and offset', () {
      expect(ShadowTokens.sm.blurRadius, 8);
      expect(ShadowTokens.sm.offset, const Offset(0, 2));
      expect(ShadowTokens.sm.color, const Color(0x33000000));
    });

    test('md has expected blur and offset', () {
      expect(ShadowTokens.md.blurRadius, 16);
      expect(ShadowTokens.md.offset, const Offset(0, 4));
      expect(ShadowTokens.md.color, const Color(0x47000000));
    });

    test('lg has expected blur and offset', () {
      expect(ShadowTokens.lg.blurRadius, 24);
      expect(ShadowTokens.lg.offset, const Offset(0, 6));
      expect(ShadowTokens.lg.color, const Color(0x59000000));
    });

    test('xl has expected blur and offset', () {
      expect(ShadowTokens.xl.blurRadius, 32);
      expect(ShadowTokens.xl.offset, const Offset(0, 8));
      expect(ShadowTokens.xl.color, const Color(0x66000000));
    });
  });
}
