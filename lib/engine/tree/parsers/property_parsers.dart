import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Maps JSON `left`/`right` to `start`/`end` for RTL-aware layout.
  static EdgeInsetsDirectional? parseEdgeInsetsDirectional(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final n = v.toDouble();
      return EdgeInsetsDirectional.all(n);
    }
    if (v is Map) {
      return EdgeInsetsDirectional.only(
        start: (v['left'] as num?)?.toDouble() ?? 0,
        top: (v['top'] as num?)?.toDouble() ?? 0,
        end: (v['right'] as num?)?.toDouble() ?? 0,
        bottom: (v['bottom'] as num?)?.toDouble() ?? 0,
      );
    }
    return null;
  }

  static MainAxisSize parseMainAxisSize(
    String? v, {
    required MainAxisSize defaultValue,
  }) {
    switch (v) {
      case 'min':
        return MainAxisSize.min;
      case 'max':
        return MainAxisSize.max;
      default:
        return defaultValue;
    }
  }

  static TextDirection? parseTextDirection(String? v) {
    switch (v) {
      case 'ltr':
        return TextDirection.ltr;
      case 'rtl':
        return TextDirection.rtl;
      default:
        return null;
    }
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
      case 'light':
        return FontWeight.w300;
      case 'w400':
      case 'normal':
        return FontWeight.normal;
      case 'w500':
      case 'medium':
        return FontWeight.w500;
      case 'w600':
      case 'semibold':
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

  static int? parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static bool parseBool(dynamic v, {bool defaultValue = true}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (v is num) return v != 0;
    return defaultValue;
  }

  static TextOverflow? parseTextOverflow(String? v) {
    switch (v) {
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'fade':
        return TextOverflow.fade;
      case 'clip':
        return TextOverflow.clip;
      case 'visible':
        return TextOverflow.visible;
      default:
        return null;
    }
  }

  static FontStyle? parseFontStyle(String? v) {
    switch (v) {
      case 'italic':
        return FontStyle.italic;
      case 'normal':
        return FontStyle.normal;
      default:
        return null;
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

  static TextInputType? parseKeyboardType(String? v) {
    switch (v) {
      case 'text':
        return TextInputType.text;
      case 'multiline':
        return TextInputType.multiline;
      case 'email':
      case 'emailAddress':
        return TextInputType.emailAddress;
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'datetime':
        return TextInputType.datetime;
      case 'name':
        return TextInputType.name;
      case 'password':
        return TextInputType.visiblePassword;
      default:
        return null;
    }
  }

  static TextInputAction? parseTextInputAction(String? v) {
    switch (v) {
      case 'done':
        return TextInputAction.done;
      case 'go':
        return TextInputAction.go;
      case 'next':
        return TextInputAction.next;
      case 'previous':
        return TextInputAction.previous;
      case 'search':
        return TextInputAction.search;
      case 'send':
        return TextInputAction.send;
      case 'newline':
        return TextInputAction.newline;
      case 'continueAction':
        return TextInputAction.continueAction;
      case 'join':
        return TextInputAction.join;
      case 'route':
        return TextInputAction.route;
      case 'emergencyCall':
        return TextInputAction.emergencyCall;
      default:
        return null;
    }
  }

  static TextCapitalization parseTextCapitalization(String? v) {
    switch (v) {
      case 'words':
        return TextCapitalization.words;
      case 'sentences':
        return TextCapitalization.sentences;
      case 'characters':
        return TextCapitalization.characters;
      case 'none':
      default:
        return TextCapitalization.none;
    }
  }

  static List<TextInputFormatter>? parseInputFormatters(dynamic v) {
    if (v is! List) return null;
    final formatters = <TextInputFormatter>[];
    for (final entry in v) {
      if (entry is! String) continue;
      if (entry == 'digitsOnly') {
        formatters.add(FilteringTextInputFormatter.digitsOnly);
      } else if (entry == 'denyWhitespace') {
        formatters.add(FilteringTextInputFormatter.deny(RegExp(r'\s')));
      } else if (entry.startsWith('allowRegex:')) {
        final pattern = entry.substring('allowRegex:'.length);
        if (pattern.isNotEmpty) {
          formatters.add(FilteringTextInputFormatter.allow(RegExp(pattern)));
        }
      } else if (entry.startsWith('denyRegex:')) {
        final pattern = entry.substring('denyRegex:'.length);
        if (pattern.isNotEmpty) {
          formatters.add(FilteringTextInputFormatter.deny(RegExp(pattern)));
        }
      }
    }
    return formatters.isEmpty ? null : formatters;
  }

  static IconData parseIconData(String? name) {
    switch (name) {
      case 'home':
        return Icons.home;
      case 'list':
        return Icons.list;
      case 'grid_view':
        return Icons.grid_view;
      case 'settings':
        return Icons.settings;
      case 'search':
        return Icons.search;
      case 'cart':
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      case 'visibility':
        return Icons.visibility;
      case 'visibility_off':
        return Icons.visibility_off;
      case 'mail':
        return Icons.mail;
      case 'lock':
        return Icons.lock;
      case 'phone':
        return Icons.phone;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'chevron_right':
        return Icons.chevron_right;
      case 'chevron_left':
        return Icons.chevron_left;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'notifications':
        return Icons.notifications;
      case 'help_outline':
        return Icons.help_outline;
      case 'credit_card':
        return Icons.credit_card;
      case 'payments':
        return Icons.payments;
      case 'check_circle':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'account_circle':
        return Icons.account_circle;
      case 'local_offer':
        return Icons.local_offer;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'error_outline':
        return Icons.error_outline;
      default:
        return Icons.circle;
    }
  }

  /// Converts a dynamic value to double.
  ///
  /// Handles: null, num types, and strings that parse to numbers.
  /// Returns null if conversion fails.
  static double? parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      try {
        return double.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Parses image fit enum string to a value for Image.fit.
  ///
  /// Valid values: 'fill', 'contain', 'cover', 'fitWidth', 'fitHeight', 'scaleDown'
  /// Returns the validated string, defaulting to 'cover'.
  ///
  /// The returned string should be mapped to BoxFit enum in the renderer.
  static String parseImageFitString(String? v) {
    if (v == null) return 'cover';
    switch (v) {
      case 'fill':
      case 'contain':
      case 'cover':
      case 'fitWidth':
      case 'fitHeight':
      case 'scaleDown':
        return v;
      default:
        return 'cover';
    }
  }

  /// Parses image source type from string.
  ///
  /// Valid values: 'network', 'asset', 'file'
  /// Default: 'network'
  static String parseImageSource(String? v) {
    switch (v) {
      case 'asset':
        return 'asset';
      case 'file':
        return 'file';
      case 'network':
      default:
        return 'network';
    }
  }
}
