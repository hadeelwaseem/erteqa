import 'package:flutter/widgets.dart';

class FormStateStore {
  static const contextKey = '_engineFormState';

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, String> _values = {};
  final Map<String, GlobalKey<FormState>> _formKeys = {};

  TextEditingController controllerFor(String key, {String? initialValue}) {
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialValue ?? ''),
    );
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue;
    }
    if (initialValue != null && !_values.containsKey(key)) {
      _values[key] = initialValue;
    }
    return controller;
  }

  FocusNode focusNodeFor(String key) {
    return _focusNodes.putIfAbsent(key, FocusNode.new);
  }

  void updateValue(String key, String value) {
    _values[key] = value;
  }

  String? valueFor(String key) => _values[key];

  Map<String, String> snapshot() => Map<String, String>.from(_values);

  GlobalKey<FormState> formKeyFor(String formId) {
    final key = formId.isEmpty ? 'default' : formId;
    return _formKeys.putIfAbsent(key, () => GlobalKey<FormState>());
  }

  bool validate(String formId) {
    final key = formId.isEmpty ? 'default' : formId;
    final formKey = _formKeys[key];
    return formKey?.currentState?.validate() ?? true;
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _values.clear();
    _formKeys.clear();
  }
}
