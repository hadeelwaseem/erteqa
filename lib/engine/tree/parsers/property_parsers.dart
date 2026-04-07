import 'package:flutter/material.dart';

/// Shared property parsing utilities for the tree-based UI engine.
class PropertyParsers {
  PropertyParsers._();

  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return null;
    }
  }

  static MainAxisAlignment parseMainAxisAlignment(String? v) {
    switch (v) {
      case 'start':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment parseCrossAxisAlignment(String? v) {
    switch (v) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

  static EdgeInsets? parseEdgeInsets(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final n = v.toDouble();
      return EdgeInsets.all(n);
    }
    if (v is Map) {
      return EdgeInsets.only(
        left: (v['left'] as num?)?.toDouble() ?? 0,
        top: (v['top'] as num?)?.toDouble() ?? 0,
        right: (v['right'] as num?)?.toDouble() ?? 0,
        bottom: (v['bottom'] as num?)?.toDouble() ?? 0,
      );
    }
    return null;
  }

  static BorderRadius? parseBorderRadius(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      return BorderRadius.circular(v.toDouble());
    }
    return null;
  }

  static FontWeight parseFontWeight(String? v) {
    switch (v) {
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

  static TextAlign parseTextAlign(String? v) {
    switch (v) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.start;
    }
  }

  static AlignmentGeometry? parseAlignment(String? v) {
    switch (v) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return null;
    }
  }
}
