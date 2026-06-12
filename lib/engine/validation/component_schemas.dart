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
      'expandAxis',
      'shadow',
      'border',
      'visibleWhen',
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
      'expandAxis': 'string (horizontal|vertical|both)',
      'shadow': 'string (sm|md|lg|xl|none)',
      'border': 'object {width, color}',
      'visibleWhen':
          'object {source: form|pageState, field: string, when: isEmpty|nonEmpty}',
    },
  );

  /// Schema: Engine page shell — not Flutter [Scaffold]; SafeArea is on [appBar].
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

  /// Schema: SingleChildScrollView — legacy; prefer pages[].scroll + list/grid.
  /// Nested scrollables are unwrapped at runtime.
  static const singleChildScrollView = ComponentSchema(
    type: 'singleChildScrollView',
    requiredProperties: {},
    optionalProperties: {'axis', 'child'},
    propertyTypes: {
      'axis': 'string (vertical|horizontal) — deprecated: use page scroll',
    },
  );

  /// Schema: Column - vertical layout with multiple children.
  static const column = ComponentSchema(
    type: 'column',
    requiredProperties: {},
    optionalProperties: {
      'mainAxisAlignment',
      'crossAxisAlignment',
      'mainAxisSize',
      'textDirection',
      'gap',
      'padding',
      'visibleWhen',
      'children', // Not in properties, but in ComponentConfig
    },
    propertyTypes: {
      'mainAxisAlignment':
          'string (start|center|end|spaceBetween|spaceAround|spaceEvenly)',
      'crossAxisAlignment': 'string (start|center|end|stretch|baseline)',
      'gap': 'number',
      'padding': 'number | object',
      'visibleWhen':
          'object {source: form|pageState, field: string, when: isEmpty|nonEmpty}',
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
      'data.queryBindings': 'object (query param bindings from pageState/form)',
      'data.pathBindings': 'object (URL path placeholder bindings from pageState)',
      'data.fallbackRequestUrl':
          'string (browse URL when pathBindings are unresolved)',
      'data.primeFromRequest': 'object (auto-select first row from source request)',
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
      'data.queryBindings': 'object (query param bindings from pageState/form)',
      'data.pathBindings': 'object (URL path placeholder bindings from pageState)',
      'data.fallbackRequestUrl':
          'string (browse URL when pathBindings are unresolved)',
      'data.primeFromRequest': 'object (auto-select first row from source request)',
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
      'icon',
      'iconPosition',
      'iconSize',
      'iconGap',
      'enabled',
      'onTap', // Runtime-injected from tap; not authored in JSON
    },
    propertyTypes: {
      'label': 'string',
      'variant': 'string (elevated|filled|outlined|text)',
      'icon': 'string (Material icon name)',
      'iconPosition': 'string (leading|trailing)',
      'iconSize': 'number',
      'iconGap': 'number',
      'enabled': 'bool',
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

  /// Schema: ContactButton - external contact CTA (WhatsApp, tel, sms, …).
  static const contactButton = ComponentSchema(
    type: 'contactButton',
    requiredProperties: {'channel', 'label'},
    optionalProperties: {
      'target',
      'targetPath',
      'backgroundColor',
      'foregroundColor',
      'fullWidth',
      'borderRadius',
      'fontSize',
      'fontWeight',
      'icon',
      'iconSize',
      'iconGap',
      'gap',
      'iconPosition',
      'enabled',
      'padding',
      'onTap',
    },
    propertyTypes: {
      'channel': 'string (whatsapp|tel|sms|email|url)',
      'label': 'string',
      'target': 'string',
      'targetPath': 'string (dataContext path)',
      'backgroundColor': 'string (hex)',
      'foregroundColor': 'string (hex)',
      'fullWidth': 'bool',
      'borderRadius': 'number',
      'fontSize': 'number',
      'fontWeight': 'string',
      'icon': 'string',
      'iconSize': 'number',
      'iconGap': 'number',
      'gap': 'number',
      'iconPosition': 'string (leading|trailing)',
      'enabled': 'bool',
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
    optionalProperties: {
      'title',
      'backgroundColor',
      'color',
      'foregroundColor',
      'titleColor',
      'showMenu',
      'menuIcon',
      'menuAction',
      'trailingIcon',
      'trailingIconActive',
      'trailingIconInactive',
      'trailingIconActivePath',
      'trailingActiveColor',
      'trailingAction',
      'titleAlign',
      'height',
      'elevation',
    },
    propertyTypes: {
      'title': 'string',
      'backgroundColor': 'string (hex #RRGGBB, #AARRGGBB, or transparent)',
      'foregroundColor': 'string (hex)',
      'titleAlign': 'string (start|center|end; start follows app direction, default start)',
      'height': 'number (optional fixed bar height)',
      'elevation': 'number (Material elevation; default 1)',
      'showMenu': 'bool (menu left, openDrawer default)',
      'menuIcon': 'string (icon name)',
      'menuAction': 'action object (default openDrawer)',
      'trailingIcon': 'string (icon name)',
      'trailingIconActive': 'string (icon when active path is true; default favorite)',
      'trailingIconInactive':
          'string (icon when active path is false; default favorite_outline)',
      'trailingIconActivePath':
          'string (boolean dataContext path, e.g. wishlist.isCurrentProductFavorite)',
      'trailingActiveColor': 'string (hex icon color when active)',
      'trailingAction': 'action object',
    },
  );

  static const divider = ComponentSchema(
    type: 'divider',
    requiredProperties: {},
    optionalProperties: {'height', 'thickness', 'color', 'margin'},
    propertyTypes: {
      'height': 'number (total vertical space; from style.height)',
      'thickness': 'number (line stroke width)',
      'color': 'string (hex; from style.color)',
      'margin': 'number | object (from style.margin)',
    },
  );

  /// Schema: SizedBox — fixed width/height gap or child constraint.
  static const sizedBox = ComponentSchema(
    type: 'sizedBox',
    requiredProperties: {},
    optionalProperties: {'width', 'height'},
    propertyTypes: {
      'width': 'number (logical px)',
      'height': 'number (logical px)',
    },
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
      'clearable',
      'clearIcon',
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
      'clearable': 'bool (suffix clear button when non-empty)',
      'clearIcon': 'string (default close)',
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
    propertyTypes: {
      'fit': 'string (expand|loose)',
      'stackLayer': 'on child: fill|positioned',
      'stackAlign': 'on child: alignment string',
      'stackInsetBottom': 'on child: number (px)',
      'stackWidthFactor': 'on child: number (0-1)',
    },
  );

  static const imageSlider = ComponentSchema(
    type: 'imageSlider',
    requiredProperties: {},
    optionalProperties: {
      'images',
      'imagesPath',
      'itemUrlPath',
      'itemAltPath',
      'fit',
      'aspectRatio',
      'autoPlay',
      'intervalMs',
      'showIndicators',
      'showIndicatorsWhenSingle',
      'indicatorPosition',
      'indicatorColor',
      'indicatorInactiveColor',
      'indicatorStyle',
      'indicatorBottomPadding',
      'animationDurationMs',
      'borderRadius',
      'enableFullscreenPreview',
      'showThumbnails',
      'showThumbnailsWhenSingle',
      'thumbnailSize',
      'thumbnailGap',
      'thumbnailBorderRadius',
      'thumbnailBorderWidth',
      'thumbnailActiveBorderColor',
      'thumbnailInactiveBorderColor',
    },
    propertyTypes: {
      'images': 'string[] | object[] {url, alt?}',
      'imagesPath': 'string (dataContext path to image array)',
      'itemUrlPath': 'string (path in image object, e.g. publicUrl)',
      'itemAltPath': 'string (path in image object for alt text)',
      'fit': 'string (cover|contain|fill|...)',
      'aspectRatio': 'number',
      'autoPlay': 'bool',
      'intervalMs': 'number',
      'showIndicators': 'bool',
      'showIndicatorsWhenSingle': 'bool',
      'indicatorPosition': 'string (top|bottom)',
      'indicatorColor': 'string (hex)',
      'indicatorInactiveColor': 'string (hex)',
      'indicatorStyle': 'string (dot|pill)',
      'indicatorBottomPadding': 'number',
      'animationDurationMs': 'number',
      'borderRadius': 'number',
      'enableFullscreenPreview': 'bool',
      'showThumbnails': 'bool',
      'showThumbnailsWhenSingle': 'bool',
      'thumbnailSize': 'number',
      'thumbnailGap': 'number',
      'thumbnailBorderRadius': 'number',
      'thumbnailBorderWidth': 'number',
      'thumbnailActiveBorderColor': 'string (hex)',
      'thumbnailInactiveBorderColor': 'string (hex)',
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

  static const appDrawer = ComponentSchema(
    type: 'appDrawer',
    requiredProperties: {},
    optionalProperties: {
      'drawerEdge',
      'width',
      'backgroundColor',
      'child',
    },
    propertyTypes: {
      'drawerEdge': 'string (start|end)',
      'width': 'number',
      'backgroundColor': 'string (hex)',
    },
  );

  static const tabs = ComponentSchema(
    type: 'tabs',
    requiredProperties: {},
    optionalProperties: {
      'selectedIndex',
      'selectedIndexPath',
      'spacing',
      'runSpacing',
      'activeColor',
      'inactiveColor',
      'indicatorWidth',
      'itemsPath',
      'itemLabelPath',
      'itemValuePath',
      'flattenItems',
      'scroll',
      'data',
      'tap',
    },
    propertyTypes: {
      'selectedIndex': 'number',
      'selectedIndexPath': 'string (dataContext path)',
      'spacing': 'number',
      'runSpacing': 'number',
      'activeColor': 'string (hex)',
      'inactiveColor': 'string (hex)',
      'indicatorWidth': 'number',
      'itemsPath': 'string (dataContext path to dynamic tab items)',
      'itemLabelPath': 'string (field on each dynamic item for title)',
      'itemValuePath': 'string (field on each dynamic item for tap metadata)',
      'flattenItems': 'string (leaves | all) — expand nested category children',
      'scroll': 'string (horizontal default | vertical for Wrap layout)',
      'data':
          'object { items?, staticItems?, requestKey?, requestUrl? } — staticItems prefix before itemsPath',
      'tap': 'action object (setPageState, reloadRequest, navigate, ...)',
    },
  );

  static const dropdown = ComponentSchema(
    type: 'dropdown',
    requiredProperties: {},
    optionalProperties: {
      'id',
      'controllerId',
      'label',
      'hint',
      'helper',
      'error',
      'emptyHint',
      'value',
      'valuePath',
      'selectedIndex',
      'selectedIndexPath',
      'data',
      'itemsPath',
      'itemLabelPath',
      'itemValuePath',
      'required',
      'validateRequired',
      'requiredMessage',
      'validationMessage',
      'enabled',
      'readOnly',
      'isDense',
      'isExpanded',
      'margin',
      'padding',
      'width',
      'color',
      'borderRadius',
      'border',
      'tap',
      'onChanged',
      'semanticsLabel',
    },
    propertyTypes: {
      'id': 'string',
      'controllerId': 'string',
      'label': 'string',
      'hint': 'string',
      'helper': 'string',
      'error': 'string',
      'emptyHint': 'string',
      'value': 'string',
      'valuePath': 'string (dataContext path)',
      'selectedIndex': 'number',
      'selectedIndexPath': 'string (dataContext path)',
      'data': 'object { items: [{ label, value, index?, disabled? }] }',
      'itemsPath': 'string (dataContext path)',
      'itemLabelPath': 'string',
      'itemValuePath': 'string',
      'required': 'bool',
      'validateRequired': 'bool',
      'requiredMessage': 'string',
      'validationMessage': 'string',
      'enabled': 'bool',
      'readOnly': 'bool',
      'isDense': 'bool (default true)',
      'isExpanded': 'bool (default false; use true in column/form)',
      'margin': 'number | object',
      'padding': 'number | object',
      'width': 'number',
      'color': 'string (hex)',
      'borderRadius': 'number',
      'border': 'object',
      'tap': 'action object (value, index, label in dataContext.tap)',
      'onChanged': 'action object',
      'semanticsLabel': 'string',
    },
  );

  static const expansionTile = ComponentSchema(
    type: 'expansionTile',
    requiredProperties: {'title'},
    optionalProperties: {
      'title',
      'subtitle',
      'leadingIcon',
      'trailingIcon',
      'initiallyExpanded',
      'maintainState',
      'enabled',
      'showDivider',
      'backgroundColor',
      'collapsedBackgroundColor',
      'iconColor',
      'textColor',
      'subtitleColor',
      'dividerColor',
      'tilePadding',
      'childrenPadding',
      'borderRadius',
      'onExpansionChanged',
      'semanticsLabel',
      'child',
      'children',
    },
    propertyTypes: {
      'title': 'string',
      'subtitle': 'string',
      'leadingIcon': 'string (Material icon name)',
      'trailingIcon': 'string (Material icon name)',
      'initiallyExpanded': 'bool',
      'maintainState': 'bool',
      'enabled': 'bool',
      'showDivider': 'bool (default false; opt-in separator below tile)',
      'backgroundColor': 'string (hex)',
      'collapsedBackgroundColor': 'string (hex)',
      'iconColor': 'string (hex)',
      'textColor': 'string (hex)',
      'subtitleColor': 'string (hex)',
      'dividerColor': 'string (hex)',
      'tilePadding': 'number | object',
      'childrenPadding': 'number | object',
      'borderRadius': 'number',
      'onExpansionChanged': 'action object (expanded in dataContext.tap)',
      'semanticsLabel': 'string',
    },
  );

  static const otpInput = ComponentSchema(
    type: 'otpInput',
    requiredProperties: {},
    optionalProperties: {
      'fieldId',
      'length',
      'boxWidth',
      'boxHeight',
      'gap',
      'readOnly',
      'enabled',
      'autofocus',
      'textDirection',
      'validateRequired',
      'validateMinLength',
      'validateMaxLength',
      'requiredMessage',
      'validationMessage',
      'color',
      'borderRadius',
      'border',
    },
    propertyTypes: {
      'fieldId': 'string (default otpCode)',
      'length': 'number (default 6)',
      'boxWidth': 'number',
      'boxHeight': 'number',
      'gap': 'number',
      'readOnly': 'bool',
      'enabled': 'bool',
      'autofocus': 'bool',
      'textDirection': 'string (ltr|rtl, default ltr)',
      'validateRequired': 'bool',
      'validateMinLength': 'number',
      'validateMaxLength': 'number',
      'requiredMessage': 'string',
      'validationMessage': 'string',
      'color': 'string (hex, from style.background)',
      'borderRadius': 'number',
      'border': 'object {width, color}',
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
      case 'contactButton':
        return contactButton;
      case 'card':
        return card;
      case 'image':
        return image;
      case 'appBar':
        return appBar;
      case 'divider':
        return divider;
      case 'sizedBox':
        return sizedBox;
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
      case 'appDrawer':
        return appDrawer;
      case 'tabs':
        return tabs;
      case 'otpInput':
        return otpInput;
      case 'dropdown':
        return dropdown;
      case 'expansionTile':
        return expansionTile;
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
      'contactButton': contactButton,
      'card': card,
      'image': image,
      'appBar': appBar,
      'divider': divider,
      'sizedBox': sizedBox,
      'icon': icon,
      'richtext': richtext,
      'textFormField': textFormField,
      'form': form,
      'videoPlayer': videoPlayer,
      'stack': stack,
      'imageSlider': imageSlider,
      'timer': timer,
      'progressIndicator': progressIndicator,
      'appDrawer': appDrawer,
      'tabs': tabs,
      'otpInput': otpInput,
      'dropdown': dropdown,
      'expansionTile': expansionTile,
      'unsupported': unsupported,
    };
  }
}
