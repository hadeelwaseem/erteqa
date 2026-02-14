import 'package:flutter/material.dart';

//TODO
/// Theme model parsed from configuration (colors + typography).
/// App-level theme; not tied to any specific feature.
class AppThemeModel {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color button;
  final Color success;
  final Color text;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  AppThemeModel({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.button,
    required this.success,
    required this.text,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });

  factory AppThemeModel.fromJson(Map<String, dynamic> json) {
    return AppThemeModel(
      primary: _hexToColor(json['primary']),
      secondary: _hexToColor(json['secondary']),
      background: _hexToColor(json['background']),
      button: _hexToColor(json['button']),
      success: _hexToColor(json['success']),
      text: _hexToColor(json['text']),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontWeight: _fontWeightFromString(json['fontWeight'] as String?),
      fontStyle: _fontStyleFromString(json['fontStyle'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': _colorToHex(primary),
      'secondary': _colorToHex(secondary),
      'background': _colorToHex(background),
      'button': _colorToHex(button),
      'success': _colorToHex(success),
      'text': _colorToHex(text),
      'fontSize': fontSize,
      'fontWeight': _fontWeightToString(fontWeight),
      'fontStyle': _fontStyleToString(fontStyle),
    };
  }

  AppThemeModel copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? button,
    Color? success,
    Color? text,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
  }) {
    return AppThemeModel(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      button: button ?? this.button,
      success: success ?? this.success,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
    );
  }

  static Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xff')));

  static String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  /// Parses fontWeight from string (e.g. "bold", "w600"). For use in component overrides.
  static FontWeight parseFontWeight(String? str) => _fontWeightFromString(str);

  /// Parses fontStyle from string (e.g. "italic"). For use in component overrides.
  static FontStyle parseFontStyle(String? str) => _fontStyleFromString(str);

  /// Parses color from hex string (e.g. "#FF0000"). For use in component overrides.
  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return _hexToColor(hex);
    } catch (_) {
      return null;
    }
  }

  static FontWeight _fontWeightFromString(String? str) {
    if (str == null) return FontWeight.normal;
    switch (str) {
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
      case 'normal':
        return FontWeight.normal;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
      case 'bold':
        return FontWeight.bold;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  static String _fontWeightToString(FontWeight weight) {
    if (weight == FontWeight.w100) return 'w100';
    if (weight == FontWeight.w200) return 'w200';
    if (weight == FontWeight.w300) return 'w300';
    if (weight == FontWeight.normal) return 'normal';
    if (weight == FontWeight.w500) return 'w500';
    if (weight == FontWeight.w600) return 'w600';
    if (weight == FontWeight.bold) return 'bold';
    if (weight == FontWeight.w800) return 'w800';
    if (weight == FontWeight.w900) return 'w900';
    return 'normal';
  }

  static FontStyle _fontStyleFromString(String? str) {
    if (str == null) return FontStyle.normal;
    return str == 'italic' ? FontStyle.italic : FontStyle.normal;
  }

  static String _fontStyleToString(FontStyle style) {
    return style == FontStyle.italic ? 'italic' : 'normal';
  }
}
