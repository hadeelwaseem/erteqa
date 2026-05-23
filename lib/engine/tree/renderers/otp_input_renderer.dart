import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../form/form_state_store.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

/// Multi-box OTP entry wired to [FormStateStore] (default field `otpCode`).
class OtpInputRenderer implements ComponentRenderer {
  static const _defaultRequiredMessage = 'هذا الحقل مطلوب';

  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final fieldId = properties['fieldId'] as String? ?? 'otpCode';
    final length = _parseInt(properties['length']) ?? 6;
    final boxWidth = PropertyParsers.parseDouble(properties['boxWidth']) ?? 48.0;
    final boxHeight = PropertyParsers.parseDouble(properties['boxHeight']) ?? 56.0;
    final gap = PropertyParsers.parseDouble(properties['gap']) ?? 8.0;
    final readOnly = properties['readOnly'] == true;
    final enabled = properties['enabled'] != false;
    final autofocus = properties['autofocus'] == true;
    final textDirection = PropertyParsers.parseTextDirection(
          properties['textDirection'] as String?,
        ) ??
        TextDirection.ltr;

    final requiredField =
        properties['required'] == true ||
        properties['validateRequired'] == true;
    final validateMinLength = _parseInt(properties['validateMinLength']);
    final validateMaxLength = _parseInt(properties['validateMaxLength']);
    final requiredMessage =
        properties['requiredMessage'] as String? ?? _defaultRequiredMessage;
    final validationMessage = properties['validationMessage'] as String?;

    final fillColor = PropertyParsers.parseColor(properties['color'] as String?);
    final borderRadius = PropertyParsers.parseBorderRadius(
      properties['borderRadius'],
    );
    final border = _parseBorder(properties['border'], dataContext);
    final theme = EngineTheme.fromDataContext(dataContext);

    final validator = _buildValidator(
      requiredField: requiredField,
      requiredMessage: requiredMessage,
      validateMinLength: validateMinLength,
      validateMaxLength: validateMaxLength,
      validationMessage: validationMessage,
    );

    final formState = _formStateFrom(dataContext);
    final initialValue = formState?.valueFor(fieldId) ?? '';

    return _OtpInputField(
      fieldId: fieldId,
      length: length,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      gap: gap,
      readOnly: readOnly,
      enabled: enabled,
      autofocus: autofocus,
      fillColor: fillColor,
      borderRadius: borderRadius,
      border: border,
      theme: theme,
      formState: formState,
      initialValue: initialValue,
      validator: validator,
      textDirection: textDirection,
    );
  }

  FormStateStore? _formStateFrom(Map<String, dynamic>? dataContext) {
    final existing = dataContext?[FormStateStore.contextKey];
    return existing is FormStateStore ? existing : null;
  }

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  FormFieldValidator<String>? _buildValidator({
    required bool requiredField,
    required String requiredMessage,
    required int? validateMinLength,
    required int? validateMaxLength,
    required String? validationMessage,
  }) {
    if (!requiredField &&
        validateMinLength == null &&
        validateMaxLength == null) {
      return null;
    }

    return (value) {
      final text = value?.trim() ?? '';
      if (requiredField && text.isEmpty) {
        return validationMessage ?? requiredMessage;
      }
      if (text.isEmpty) return null;
      if (validateMinLength != null && text.length < validateMinLength) {
        return validationMessage ??
            'يجب أن يكون $validateMinLength أحرف على الأقل';
      }
      if (validateMaxLength != null && text.length > validateMaxLength) {
        return validationMessage ??
            'يجب ألا يتجاوز $validateMaxLength حرفاً';
      }
      return null;
    };
  }

  Border? _parseBorder(dynamic v, Map<String, dynamic>? dataContext) {
    if (v is! Map) return null;
    final width = (v['width'] as num?)?.toDouble() ?? 1.0;
    final theme = EngineTheme.fromDataContext(dataContext);
    final color =
        PropertyParsers.parseColor(v['color'] as String?) ??
        theme?.inputBorderColor ??
        const Color(0xFF94A3B8);
    return Border.all(width: width, color: color);
  }
}

class _OtpInputField extends StatefulWidget {
  const _OtpInputField({
    required this.fieldId,
    required this.length,
    required this.boxWidth,
    required this.boxHeight,
    required this.gap,
    required this.readOnly,
    required this.enabled,
    required this.autofocus,
    required this.fillColor,
    required this.borderRadius,
    required this.border,
    required this.theme,
    required this.formState,
    required this.initialValue,
    required this.validator,
    required this.textDirection,
  });

  final String fieldId;
  final int length;
  final double boxWidth;
  final double boxHeight;
  final double gap;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final EngineTheme? theme;
  final FormStateStore? formState;
  final String initialValue;
  final FormFieldValidator<String>? validator;
  final TextDirection textDirection;

  @override
  State<_OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<_OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    final chars = widget.initialValue.padRight(widget.length).split('');
    _controllers = List.generate(
      widget.length,
      (i) => TextEditingController(
        text: i < chars.length && chars[i] != ' ' ? chars[i] : '',
      ),
    );
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    if (widget.autofocus && widget.enabled && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) {
          _focusNodes.first.requestFocus();
        }
      });
    }
    _syncFormStore();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _combined =>
      _controllers.map((c) => c.text).join().replaceAll(RegExp(r'\s'), '');

  void _syncFormStore() {
    widget.formState?.updateValue(widget.fieldId, _combined);
  }

  void _notifyFormField(FormFieldState<String>? fieldState) {
    _syncFormStore();
    fieldState?.didChange(_combined);
  }

  InputDecoration _boxDecoration() {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final fill =
        widget.fillColor ??
        widget.theme?.surfaceColor ??
        const Color(0xFFFFFFFF);
    final borderColor =
        widget.border?.top.color ??
        widget.theme?.inputBorderColor ??
        const Color(0xFF94A3B8);
    final borderWidth = widget.border?.top.width ?? 1.0;

    return InputDecoration(
      filled: true,
      fillColor: fill,
      contentPadding: EdgeInsets.zero,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: widget.theme?.primaryColor ?? const Color(0xFFF97316),
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (fieldState) {
        final row = Directionality(
          textDirection: widget.textDirection,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection: widget.textDirection,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                SizedBox(
                  width: widget.boxWidth,
                  height: widget.boxHeight,
                  child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      enabled: widget.enabled,
                      readOnly: widget.readOnly,
                      autofocus: widget.autofocus && i == 0,
                      keyboardType: TextInputType.number,
                      textDirection: widget.textDirection,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: _boxDecoration(),
                      onChanged: (value) {
                        final digit = value.replaceAll(RegExp(r'\D'), '');
                        if (digit.length > 1) {
                          _controllers[i].text =
                              digit.substring(digit.length - 1);
                          _controllers[i].selection = const TextSelection.collapsed(
                            offset: 1,
                          );
                        } else if (digit.isNotEmpty) {
                          _controllers[i].text = digit;
                          if (i < widget.length - 1) {
                            _focusNodes[i + 1].requestFocus();
                          }
                        } else if (value.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                        _notifyFormField(fieldState);
                        if (fieldState.hasError) {
                          fieldState.validate();
                        }
                      },
                      onTap: () {
                        _controllers[i].selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controllers[i].text.length,
                        );
                      },
                      onEditingComplete: () {
                        if (i < widget.length - 1) {
                          _focusNodes[i + 1].requestFocus();
                        }
                      },
                    ),
                ),
              ],
            ],
          ),
        );

        final needsMaterial =
            context.findAncestorWidgetOfExactType<Material>() == null;
        final content = needsMaterial
            ? Material(type: MaterialType.transparency, child: row)
            : row;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  fieldState.errorText ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.theme?.errorColor ?? const Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
