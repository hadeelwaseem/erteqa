import 'package:flutter/material.dart';

class StoreColorsModel {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color button;
  final Color success;
  final Color text;

  StoreColorsModel({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.button,
    required this.success,
    required this.text,
  });

  factory StoreColorsModel.fromJson(Map<String, dynamic> json) {
    return StoreColorsModel(
      primary: _hexToColor(json['primary']),
      secondary: _hexToColor(json['secondary']),
      background: _hexToColor(json['background']),
      button: _hexToColor(json['button']),
      success: _hexToColor(json['success']),
      text: _hexToColor(json['text']),
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
    };
  }

  StoreColorsModel copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? button,
    Color? success,
    Color? text,
  }) {
    return StoreColorsModel(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      button: button ?? this.button,
      success: success ?? this.success,
      text: text ?? this.text,
    );
  }

  static Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xff')));

  static String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}
