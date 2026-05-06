import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../actions/action_dispatcher.dart';
import '../../component_renderer/component_renderer.dart';
import '../../form/form_state_store.dart';
import '../parsers/property_parsers.dart';

class TextFormFieldRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final fieldId = properties['id'] as String? ?? '';
    final controllerId = properties['controllerId'] as String?;
    final initialValue =
        properties['initialValue'] as String? ?? properties['value'] as String?;

    final label = properties['label'] as String?;
    final hint = properties['hint'] as String?;
    final helper = properties['helper'] as String?;
    final error = properties['error'] as String?;
    final prefixText = properties['prefixText'] as String?;
    final suffixText = properties['suffixText'] as String?;
    final prefixIconName = properties['prefixIcon'] as String?;
    final suffixIconName = properties['suffixIcon'] as String?;

    final autofocus = properties['autofocus'] == true;
    final enabled = properties['enabled'] != false;
    final readOnly = properties['readOnly'] == true;
    final obscureText = properties['obscureText'] == true;
    final autocorrect = properties['autocorrect'] != false;
    final enableSuggestions = properties['enableSuggestions'] != false;
    final expands = properties['expands'] == true;

    final keyboardType = PropertyParsers.parseKeyboardType(
      properties['keyboardType'] as String?,
    );
    final textInputAction = PropertyParsers.parseTextInputAction(
      properties['textInputAction'] as String?,
    );
    final textCapitalization = PropertyParsers.parseTextCapitalization(
      properties['textCapitalization'] as String?,
    );
    final textAlign = PropertyParsers.parseTextAlign(
      properties['textAlign'] as String?,
    );

    final inputFormatters = PropertyParsers.parseInputFormatters(
      properties['inputFormatters'],
    );

    final maxLines = _parseInt(properties['maxLines']);
    final minLines = _parseInt(properties['minLines']);
    final maxLength = _parseInt(properties['maxLength']);

    final requiredField = properties['required'] == true;
    final requiredMessage =
        properties['requiredMessage'] as String? ?? 'Required';

    final onChangedAction = properties['onChanged'] as Map<String, dynamic>?;
    final onSubmittedAction =
        properties['onSubmitted'] as Map<String, dynamic>?;

    final padding = PropertyParsers.parseEdgeInsets(properties['padding']);
    final margin = PropertyParsers.parseEdgeInsets(properties['margin']);
    final color = PropertyParsers.parseColor(properties['color'] as String?);
    final borderRadius = PropertyParsers.parseBorderRadius(
      properties['borderRadius'],
    );
    final width = PropertyParsers.parseDouble(properties['width']);
    final height = PropertyParsers.parseDouble(properties['height']);
    final border = _parseBorder(properties['border']);
    final shadow = _parseShadow(properties['shadow']);

    final controllerKey = controllerId ?? fieldId;
    final formState = _resolveFormState(dataContext);
    final controller = formState.controllerFor(
      controllerKey.isEmpty ? 'field_${config.hashCode}' : controllerKey,
      initialValue: initialValue,
    );

    final hasBoxDecoration =
        color != null ||
        borderRadius != null ||
        border != null ||
        shadow != null;

    return Builder(
      builder: (context) {
        final dispatcher = _resolveDispatcher(dataContext, context);
        final field = TextFormField(
          controller: controller,
          autofocus: autofocus,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          expands: expands,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          textAlign: textAlign,
          inputFormatters: inputFormatters,
          maxLines: expands ? null : (maxLines ?? 1),
          minLines: expands ? null : minLines,
          maxLength: maxLength,
          autovalidateMode: requiredField
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helper,
            errorText: error,
            prefixText: prefixText,
            suffixText: suffixText,
            prefixIcon: prefixIconName != null
                ? Icon(PropertyParsers.parseIconData(prefixIconName))
                : null,
            suffixIcon: suffixIconName != null
                ? Icon(PropertyParsers.parseIconData(suffixIconName))
                : null,
            border: hasBoxDecoration ? InputBorder.none : null,
          ),
          validator: requiredField
              ? (value) => value == null || value.trim().isEmpty
                    ? requiredMessage
                    : null
              : null,
          onChanged: (value) {
            if (controllerKey.isNotEmpty) {
              formState.updateValue(controllerKey, value);
            }
            if (onChangedAction != null && dispatcher != null) {
              dispatcher.dispatch(
                onChangedAction,
                value: value,
                fieldId: fieldId,
              );
            }
          },
          onFieldSubmitted: (value) {
            if (controllerKey.isNotEmpty) {
              formState.updateValue(controllerKey, value);
            }
            if (onSubmittedAction != null && dispatcher != null) {
              dispatcher.dispatch(
                onSubmittedAction,
                value: value,
                fieldId: fieldId,
              );
            }
          },
        );

        if (!hasBoxDecoration && padding == null && margin == null) {
          return field;
        }

        return Container(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          decoration: hasBoxDecoration
              ? BoxDecoration(
                  color: color,
                  borderRadius: borderRadius,
                  border: border,
                  boxShadow: shadow != null ? [shadow] : null,
                )
              : null,
          child: field,
        );
      },
    );
  }

  FormStateStore _resolveFormState(Map<String, dynamic>? dataContext) {
    if (dataContext == null) return FormStateStore();
    final existing = dataContext[FormStateStore.contextKey];
    if (existing is FormStateStore) return existing;
    final store = FormStateStore();
    dataContext[FormStateStore.contextKey] = store;
    return store;
  }

  EngineActionDispatcher? _resolveDispatcher(
    Map<String, dynamic>? dataContext,
    BuildContext context,
  ) {
    if (dataContext != null) {
      final existing = dataContext[EngineActionDispatcher.contextKey];
      if (existing is EngineActionDispatcher) return existing;
    }
    final dispatcher = EngineActionDispatcher(context: context);
    dataContext?[EngineActionDispatcher.contextKey] = dispatcher;
    return dispatcher;
  }

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  BoxShadow? _parseShadow(dynamic v) {
    if (v == null || v == 'none') return null;
    switch (v) {
      case 'sm':
        return const BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        );
      case 'md':
        return const BoxShadow(
          color: Color(0x26000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        );
      case 'lg':
        return const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        );
      case 'xl':
        return const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        );
      default:
        return null;
    }
  }

  Border? _parseBorder(dynamic v) {
    if (v is! Map) return null;
    final width = (v['width'] as num?)?.toDouble() ?? 1.0;
    final color =
        PropertyParsers.parseColor(v['color'] as String?) ??
        const Color(0xFFE2E8F0);
    return Border.all(width: width, color: color);
  }
}
