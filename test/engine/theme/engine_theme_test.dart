import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sooq_merchant/config/models/mobile_theme_config.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final config = MobileThemeConfig.fromJson({
    'colors': {'text': '#0F172A', 'primary': '#1D4ED8'},
    'typography': {'fontFamily': 'Tajawal', 'scale': {'md': 16}},
    'buttons': {'md': {'radius': 12}},
  });

  test('fromDataContext round-trips EngineTheme', () {
    final engine = EngineTheme.fromConfig(config);
    final ctx = <String, dynamic>{EngineTheme.contextKey: engine};
    expect(EngineTheme.fromDataContext(ctx), same(engine));
  });

  test('textColor matches theme.colors.text hex', () {
    final engine = EngineTheme.fromConfig(config);
    expect(engine.textColor, const Color(0xFF0F172A));
  });

  test('buttonMd.radius is 12 from config', () {
    final engine = EngineTheme.fromConfig(config);
    expect(engine.buttonMd.radius, 12);
  });

  test('radiusMd and mutedColor use theme config', () {
    final engine = EngineTheme.fromConfig(MobileThemeConfig.defaults());
    expect(engine.radiusMd, 10);
    expect(engine.mutedColor, const Color(0xFF475569));
  });

  test('toThemeData uses Material 3 and primary color', () {
    final themeData = EngineTheme.toThemeData(
      MobileThemeConfig.fromJson({
        'colors': {
          'primary': '#1D4ED8',
          'background': '#F1F5F9',
          'text': '#0F172A',
        },
        'typography': {'fontFamily': 'Roboto'},
      }),
    );
    expect(themeData.useMaterial3, isTrue);
    expect(themeData.colorScheme.primary, const Color(0xFF1D4ED8));
    expect(themeData.scaffoldBackgroundColor, const Color(0xFFF1F5F9));
  });

  test('toThemeData with Tajawal config uses fontFamily apply when fetching disabled', () {
    final themeData = EngineTheme.toThemeData(config);
    expect(themeData.useMaterial3, isTrue);
    expect(themeData.textTheme.bodyMedium?.fontFamily, 'Tajawal');
  });
}
