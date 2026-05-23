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

  /// Documented fields for JSON actions with `type: navigate` (node `tap`,
  /// timer `tap`, cubitCall `onSuccess` / `onFailure`).
  ///
  /// `navigation_type` aliases (see [parseNavigationType]):
  /// - push: `push`, `stack`
  /// - clear stack: `clear_stack`, `clearstack`, `reset`, `go`
  /// - omitted / unknown: `clear_stack` (default, `context.go`)
  static const Map<String, String> navigateActionPropertyTypes = {
    'type': 'string (navigate)',
    'route': 'string (required)',
    'navigation_type':
        'string? push|stack|clear_stack|clearstack|reset|go — default clear_stack',
    'requireValidForm': 'bool?',
    'formId': 'string?',
  };

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
      'expand',
      'shadow',
      'border',
      'child', // Not in properties map, but allowed in ComponentConfig
    },
    propertyTypes: {
      'padding': 'number | object',
      'margin': 'number | object',
      'color': 'string (hex)',
      'borderRadius': 'number',
      'width': 'number',
      'height': 'number',
      'expand': 'bool (fill width/height; scroll-safe via minHeight/viewport)',
      'shadow': 'string (sm|md|lg|xl|none)',
      'border': 'object {width, color}',
    },
  );

  /// Schema: Scaffold - top-level page wrapper with SafeArea.
  static const scaffold = ComponentSchema(
    type: 'scaffold',
    requiredProperties: {},
    optionalProperties: {
      'backgroundColor',
      'pageScroll', // Injected from pages[].scroll via VariantRepository
      'child', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'backgroundColor': 'string (hex)',
      'pageScroll': 'string (vertical|none)',
    },
  );

  /// Schema: SingleChildScrollView - scrollable wrapper with a single child.
  static const singleChildScrollView = ComponentSchema(
    type: 'singleChildScrollView',
    requiredProperties: {},
    optionalProperties: {'axis', 'child'},
    propertyTypes: {'axis': 'string (vertical|horizontal)'},
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
      'gap',
      'children', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'mainAxisAlignment':
          'string (start|center|end|spaceBetween|spaceAround|spaceEvenly)',
      'crossAxisAlignment': 'string (start|center|end|stretch|baseline)',
      'gap': 'number',
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
      'gap',
      'children', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'mainAxisAlignment':
          'string (start|center|end|spaceBetween|spaceAround|spaceEvenly)',
      'crossAxisAlignment': 'string (start|center|end|stretch|baseline)',
      'gap': 'number',
    },
  );

  /// Schema: ListView - dynamic list with builder definition.
  static const listView = ComponentSchema(
    type: 'listView',
    requiredProperties: {},
    optionalProperties: {
      'scrollDirection',
      'itemBuilder',
      'items',
      'enableInnerScroll',
      'requestKey',
      'emptyMessage',
      'errorMessage',
    },
    propertyTypes: {
      'scrollDirection': 'string (vertical|horizontal)',
      'itemBuilder': 'object (type=repeat, source=string|array, item=object)',
      'requestKey': 'string (matches VariantScreen request key)',
      'emptyMessage': 'string (localized empty state)',
      'errorMessage': 'string (localized error state)',
    },
  );

  /// Schema: GridView - static or dynamic grid with spacing and builder support.
  static const gridView = ComponentSchema(
    type: 'gridView',
    requiredProperties: {},
    optionalProperties: {
      'crossAxisCount',
      'mainAxisSpacing',
      'crossAxisSpacing',
      'scrollDirection',
      'itemBuilder',
      'children',
      'enableInnerScroll',
      'childAspectRatio',
      'requestKey',
      'emptyMessage',
      'errorMessage',
    },
    propertyTypes: {
      'crossAxisCount': 'number (integer)',
      'mainAxisSpacing': 'number',
      'crossAxisSpacing': 'number',
      'childAspectRatio': 'number',
      'scrollDirection': 'string (vertical|horizontal)',
      'itemBuilder': 'object (type=repeat, source=string|array, item=object)',
      'requestKey': 'string (matches VariantScreen request key)',
      'emptyMessage': 'string (localized empty state)',
      'errorMessage': 'string (localized error state)',
    },
  );

  /// Schema: Text - leaf widget displaying static or dynamic text.
  ///
  /// Runtime expects at least one of [value] or [valuePath]; validation does
  /// not enforce XOR (lenient for production JSON that uses valuePath only).
  static const text = ComponentSchema(
    type: 'text',
    requiredProperties: {},
    optionalProperties: {
      'value',
      'valuePath',
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
      'valuePath': 'string (dataContext path)',
      'fontSize': 'number',
      'fontWeight': 'string (w100|w200|...|w900|bold|normal)',
      'color': 'string (hex)',
      'textAlign': 'string (left|center|right|justify)',
    },
  );

  /// Schema: Button - interactive element with label and optional styling.
  ///
  /// [onTap] is injected at render time by [ScreenRenderer] from JSON [tap];
  /// do not author onTap in JSON. Use node-level tap instead.
  static const button = ComponentSchema(
    type: 'button',
    requiredProperties: {}, // 'label' recommended but not enforced
    optionalProperties: {
      'label',
      'variant',
      'foregroundColor',
      'maxWidth',
      'fullWidth',
      'fontSize',
      'fontWeight',
      'letterSpacing',
      'backgroundColor',
      'textColor',
      'borderRadius',
      'padding',
      'alignment',
      'onTap', // Runtime-injected from tap; not authored in JSON
    },
    propertyTypes: {
      'label': 'string',
      'variant': 'string (elevated|filled|outlined|text)',
      'backgroundColor': 'string (hex)',
      'textColor': 'string (hex)',
      'borderRadius': 'number',
      'padding': 'number | object',
      'fullWidth': 'bool',
      'fontSize': 'number',
      'fontWeight': 'string (bold|w600|...)',
      'letterSpacing': 'number',
      'onTap': 'VoidCallback (runtime-injected)',
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
    optionalProperties: {'flex', 'width', 'height'},
    propertyTypes: {
      'flex': 'number (integer)',
      'width': 'number',
      'height': 'number',
    },
  );

  /// Schema: Image - displays images from network, asset, or file sources.
  static const image = ComponentSchema(
    type: 'image',
    requiredProperties: {'url'},
    optionalProperties: {
      'source', // 'network', 'asset', 'file'
      'urlPath',
      'width',
      'height',
      'aspectRatio',
      'fit', // How to fit the image
      'errorPlaceholder',
      'loadingPlaceholder',
    },
    propertyTypes: {
      'url': 'string',
      'urlPath': 'string (dataContext path)',
      'source': 'string (network|asset|file)',
      'width': 'number',
      'height': 'number',
      'aspectRatio': 'number',
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
    optionalProperties: {
      'value',
      'color',
      'fontSize',
      'fontWeight',
      'textAlign',
      'height',
    },
  );

  static const textFormField = ComponentSchema(
    type: 'textFormField',
    requiredProperties: {},
    optionalProperties: {
      'id',
      'label',
      'hint',
      'helper',
      'error',
      'prefixText',
      'suffixText',
      'prefixIcon',
      'suffixIcon',
      'controllerId',
      'initialValue',
      'value',
      'keyboardType',
      'textInputAction',
      'textCapitalization',
      'autofocus',
      'enabled',
      'readOnly',
      'obscureText',
      'autocorrect',
      'enableSuggestions',
      'maxLines',
      'minLines',
      'maxLength',
      'expands',
      'textAlign',
      'textDirection',
      'required',
      'requiredMessage',
      'validateRequired',
      'validateEmail',
      'validatePhone',
      'validatePassword',
      'validateMinLength',
      'validateMaxLength',
      'validatePattern',
      'validationMessage',
      'inputFormatters',
      'onChanged',
      'onSubmitted',
      'padding',
      'margin',
      'color',
      'borderRadius',
      'width',
      'height',
      'border',
      'shadow',
    },
    propertyTypes: {
      'id': 'string',
      'label': 'string',
      'hint': 'string',
      'helper': 'string',
      'error': 'string',
      'prefixText': 'string',
      'suffixText': 'string',
      'prefixIcon': 'string',
      'suffixIcon': 'string',
      'controllerId': 'string',
      'initialValue': 'string',
      'value': 'string',
      'keyboardType': 'string',
      'textInputAction': 'string',
      'textCapitalization': 'string',
      'autofocus': 'bool',
      'enabled': 'bool',
      'readOnly': 'bool',
      'obscureText': 'bool',
      'autocorrect': 'bool',
      'enableSuggestions': 'bool',
      'maxLines': 'number (integer)',
      'minLines': 'number (integer)',
      'maxLength': 'number (integer)',
      'expands': 'bool',
      'textAlign': 'string (left|center|right|justify)',
      'textDirection': 'string (ltr|rtl)',
      'required': 'bool',
      'requiredMessage': 'string',
      'validateRequired': 'bool',
      'validateEmail': 'bool',
      'validatePhone': 'bool',
      'validatePassword': 'bool',
      'validateMinLength': 'number (integer)',
      'validateMaxLength': 'number (integer)',
      'validatePattern': 'string',
      'validationMessage': 'string',
      'inputFormatters': 'array (string)',
      'onChanged': 'action object',
      'onSubmitted': 'action object',
      'padding': 'number | object',
      'margin': 'number | object',
      'color': 'string (hex)',
      'borderRadius': 'number',
      'width': 'number',
      'height': 'number',
      'border': 'object',
      'shadow': 'string',
    },
  );

  static const form = ComponentSchema(
    type: 'form',
    requiredProperties: {},
    optionalProperties: {'id', 'formId', 'child', 'children'},
    propertyTypes: {'id': 'string', 'formId': 'string'},
  );

  static const videoPlayer = ComponentSchema(
    type: 'videoPlayer',
    requiredProperties: {'url'},
    optionalProperties: {
      'semanticType',
      'autoplay',
      'showControls',
      'height',
      'borderRadius',
    },
  );

  static const stack = ComponentSchema(
    type: 'stack',
    requiredProperties: {},
    optionalProperties: {'fit', 'children'},
    propertyTypes: {'fit': 'string (expand|loose)'},
  );

  static const imageSlider = ComponentSchema(
    type: 'imageSlider',
    requiredProperties: {'images'},
    optionalProperties: {
      'fit',
      'autoPlay',
      'intervalMs',
      'showIndicators',
      'indicatorPosition',
      'indicatorColor',
      'indicatorInactiveColor',
      'indicatorStyle',
      'indicatorBottomPadding',
      'animationDurationMs',
    },
    propertyTypes: {
      'images': 'string[] | object[] {url, alt?}',
      'fit': 'string (cover|contain|fill|...)',
      'autoPlay': 'bool',
      'intervalMs': 'number',
      'showIndicators': 'bool',
      'indicatorPosition': 'string (top|bottom)',
      'indicatorColor': 'string (hex)',
      'indicatorInactiveColor': 'string (hex)',
      'indicatorStyle': 'string (dot|pill)',
      'indicatorBottomPadding': 'number',
      'animationDurationMs': 'number',
    },
  );

  static const progressIndicator = ComponentSchema(
    type: 'progressIndicator',
    requiredProperties: {},
    optionalProperties: {'color', 'strokeWidth', 'size'},
    propertyTypes: {
      'color': 'string (hex)',
      'strokeWidth': 'number',
      'size': 'number',
    },
  );

  static const timer = ComponentSchema(
    type: 'timer',
    requiredProperties: {'durationMs'},
    optionalProperties: {'route', 'tap'},
    propertyTypes: {
      'durationMs': 'number',
      'route': 'string',
      'tap': 'action object (navigate: see navigateActionPropertyTypes)',
    },
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
      case 'singleChildScrollView':
        return singleChildScrollView;
      case 'column':
        return column;
      case 'row':
        return row;
      case 'listView':
        return listView;
      case 'gridView':
        return gridView;
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
      case 'textFormField':
        return textFormField;
      case 'form':
        return form;
      case 'videoPlayer':
        return videoPlayer;
      case 'stack':
        return stack;
      case 'imageSlider':
        return imageSlider;
      case 'timer':
        return timer;
      case 'progressIndicator':
        return progressIndicator;
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
      'singleChildScrollView': singleChildScrollView,
      'column': column,
      'row': row,
      'listView': listView,
      'gridView': gridView,
      'text': text,
      'button': button,
      'card': card,
      'spacer': spacer,
      'image': image,
      'appBar': appBar,
      'divider': divider,
      'icon': icon,
      'richtext': richtext,
      'textFormField': textFormField,
      'form': form,
      'videoPlayer': videoPlayer,
      'stack': stack,
      'imageSlider': imageSlider,
      'timer': timer,
      'progressIndicator': progressIndicator,
      'unsupported': unsupported,
    };
  }
}
