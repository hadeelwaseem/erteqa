import 'component_schema.dart';

/// Centralized schema definitions for all supported component types.
///
/// Each schema specifies:
/// - Required properties (must be present in JSON)
/// - Optional properties (nice-to-have, defaults applied if missing)
/// - Property type hints (for documentation and advanced validation)
///
/// DESIGN:
/// - Schemas are immutable and versioned with component types
/// - New components should add schema definition here
/// - Helps catch config errors during parsing (before render time)
///
/// EVOLUTION:
/// As JSON configs grow, schemas become documentation of what's valid.
/// Enables deprecation warnings, migration guides, and validation reports.
class ComponentSchemas {
  ComponentSchemas._();

  /// Schema: Layout container with padding/margin and a single child.
  static const container = ComponentSchema(
    type: 'container',
    requiredProperties: {},
    optionalProperties: {
      'padding',
      'margin',
      'color',
      'borderRadius',
      'width',
      'height',
      'child', // Not in properties map, but allowed in ComponentConfig
    },
    propertyTypes: {
      'padding': 'number | object',
      'margin': 'number | object',
      'color': 'string (hex)',
      'borderRadius': 'number',
      'width': 'number',
      'height': 'number',
    },
  );

  /// Schema: Scaffold - top-level page wrapper with SafeArea.
  static const scaffold = ComponentSchema(
    type: 'scaffold',
    requiredProperties: {},
    optionalProperties: {
      'backgroundColor',
      'child', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {'backgroundColor': 'string (hex)'},
  );

  /// Schema: Column - vertical layout with multiple children.
  static const column = ComponentSchema(
    type: 'column',
    requiredProperties: {},
    optionalProperties: {
      'mainAxisAlignment',
      'crossAxisAlignment',
      'mainAxisSize',
      'verticalDirection',
      'textDirection',
      'children', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'mainAxisAlignment':
          'string (start|center|end|spaceBetween|spaceAround|spaceEvenly)',
      'crossAxisAlignment': 'string (start|center|end|stretch|baseline)',
    },
  );

  /// Schema: Row - horizontal layout with multiple children.
  static const row = ComponentSchema(
    type: 'row',
    requiredProperties: {},
    optionalProperties: {
      'mainAxisAlignment',
      'crossAxisAlignment',
      'mainAxisSize',
      'verticalDirection',
      'textDirection',
      'children', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'mainAxisAlignment':
          'string (start|center|end|spaceBetween|spaceAround|spaceEvenly)',
      'crossAxisAlignment': 'string (start|center|end|stretch|baseline)',
    },
  );

  /// Schema: Text - leaf widget displaying static or dynamic text.
  static const text = ComponentSchema(
    type: 'text',
    requiredProperties: {'value'},
    optionalProperties: {
      'fontSize',
      'fontWeight',
      'color',
      'textAlign',
      'maxLines',
      'overflow',
      'fontStyle',
      'letterSpacing',
      'wordSpacing',
    },
    propertyTypes: {
      'value': 'string',
      'fontSize': 'number',
      'fontWeight': 'string (w100|w200|...|w900|bold|normal)',
      'color': 'string (hex)',
      'textAlign': 'string (left|center|right|justify)',
    },
  );

  /// Schema: Button - interactive element with label and optional styling.
  static const button = ComponentSchema(
    type: 'button',
    requiredProperties: {}, // 'label' recommended but not enforced
    optionalProperties: {
      'label',
      'backgroundColor',
      'borderRadius',
      'padding',
      'alignment',
      'onPressed', // For future event binding
    },
    propertyTypes: {
      'label': 'string',
      'backgroundColor': 'string (hex)',
      'borderRadius': 'number',
      'padding': 'number | object',
    },
  );

  /// Schema: Card - Material card wrapper with elevation and styling.
  static const card = ComponentSchema(
    type: 'card',
    requiredProperties: {},
    optionalProperties: {
      'elevation',
      'borderRadius',
      'color',
      'shadowColor',
      'margin',
      'child', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'elevation': 'number',
      'borderRadius': 'number',
      'color': 'string (hex)',
      'shadowColor': 'string (hex)',
      'margin': 'number | object',
    },
  );

  /// Schema: Spacer - flexible spacing element.
  static const spacer = ComponentSchema(
    type: 'spacer',
    requiredProperties: {},
    optionalProperties: {'flex'},
    propertyTypes: {'flex': 'number (integer)'},
  );

  /// Schema: Image - displays images from network, asset, or file sources.
  static const image = ComponentSchema(
    type: 'image',
    requiredProperties: {'url'},
    optionalProperties: {
      'source', // 'network', 'asset', 'file'
      'width',
      'height',
      'fit', // How to fit the image
      'errorPlaceholder',
      'loadingPlaceholder',
    },
    propertyTypes: {
      'url': 'string',
      'source': 'string (network|asset|file)',
      'width': 'number',
      'height': 'number',
      'fit': 'string (fill|contain|cover|fitWidth|fitHeight|scaleDown)',
    },
  );

  static const appBar = ComponentSchema(
    type: 'appBar',
    requiredProperties: {},
    optionalProperties: {'title', 'backgroundColor', 'color'},
  );

  static const divider = ComponentSchema(
    type: 'divider',
    requiredProperties: {},
    optionalProperties: {'thickness', 'color'},
  );

  static const icon = ComponentSchema(
    type: 'icon',
    requiredProperties: {},
    optionalProperties: {'name', 'size', 'color'},
  );

  static const richtext = ComponentSchema(
    type: 'richtext',
    requiredProperties: {},
    optionalProperties: {'value', 'color'},
  );

  static const unsupported = ComponentSchema(
    type: 'unsupported',
    requiredProperties: {},
    optionalProperties: {'id', 'rawType', 'data'},
  );

  /// Returns schema for a component type.
  ///
  /// Returns null if type is unknown (allows graceful degradation).
  static ComponentSchema? getSchema(String typeName) {
    switch (typeName) {
      case 'container':
        return container;
      case 'scaffold':
        return scaffold;
      case 'column':
        return column;
      case 'row':
        return row;
      case 'text':
        return text;
      case 'button':
        return button;
      case 'card':
        return card;
      case 'spacer':
        return spacer;
      case 'image':
        return image;
      case 'appBar':
        return appBar;
      case 'divider':
        return divider;
      case 'icon':
        return icon;
      case 'richtext':
        return richtext;
      case 'unsupported':
        return unsupported;
      default:
        return null;
    }
  }

  /// Returns all defined schemas.
  static Map<String, ComponentSchema> getAll() {
    return {
      'container': container,
      'scaffold': scaffold,
      'column': column,
      'row': row,
      'text': text,
      'button': button,
      'card': card,
      'spacer': spacer,
      'image': image,
      'appBar': appBar,
      'divider': divider,
      'icon': icon,
      'richtext': richtext,
      'unsupported': unsupported,
    };
  }
}
