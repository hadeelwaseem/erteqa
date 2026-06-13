import 'package:flutter/painting.dart';

import 'engine_theme.dart';
import 'shadow_tokens.dart';

/// Parses JSON shadow preset strings into [BoxShadow] or Material elevation.
abstract final class ShadowParser {
  /// Resolves `none`, `sm`, `md`, `lg`, `xl` to a [BoxShadow]; null/unknown → null.
  static BoxShadow? parseBoxShadowPreset(dynamic value) {
    if (value == null || value == 'none') return null;
    switch (value) {
      case 'sm':
        return ShadowTokens.sm;
      case 'md':
        return ShadowTokens.md;
      case 'lg':
        return ShadowTokens.lg;
      case 'xl':
        return ShadowTokens.xl;
      default:
        return null;
    }
  }

  /// Maps preset strings to Material elevation for card/appBar surfaces.
  static double? materialElevationForPreset(String? preset) {
    if (preset == null || preset == 'none') return 0;
    switch (preset) {
      case 'sm':
        return 1;
      case 'md':
        return 2;
      case 'lg':
        return 4;
      case 'xl':
        return 8;
      default:
        return null;
    }
  }

  /// Resolves BoxShadow from explicit `shadow` prop or [EngineTheme.defaultShadowPreset].
  static BoxShadow? resolveBoxShadowPreset(
    Map<String, dynamic> properties,
    Map<String, dynamic>? dataContext, {
    required String componentType,
  }) {
    if (properties.containsKey('shadow')) {
      return parseBoxShadowPreset(properties['shadow']);
    }
    final preset =
        EngineTheme.fromDataContext(dataContext)?.defaultShadowPreset(
      componentType,
    );
    if (preset != null) {
      return parseBoxShadowPreset(preset);
    }
    return null;
  }
}
