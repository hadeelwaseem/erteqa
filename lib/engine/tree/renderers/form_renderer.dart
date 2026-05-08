import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../form/form_state_store.dart';

class FormRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final formState = _resolveFormState(dataContext);
    final formId = config.properties['formId'] as String? ??
        config.properties['id'] as String? ??
        '';
    final formKey = formState.formKeyFor(formId);

    final child = _resolveChild(config, buildChild);
    if (child == null) return const SizedBox.shrink();

    return Form(key: formKey, child: child);
  }

  FormStateStore _resolveFormState(Map<String, dynamic>? dataContext) {
    if (dataContext == null) return FormStateStore();
    final existing = dataContext[FormStateStore.contextKey];
    if (existing is FormStateStore) return existing;
    final store = FormStateStore();
    dataContext[FormStateStore.contextKey] = store;
    return store;
  }

  Widget? _resolveChild(
    ComponentConfig config,
    ComponentWidgetBuilder buildChild,
  ) {
    if (config.child != null) {
      return buildChild(config.child!);
    }
    final children = config.children;
    if (children == null || children.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.map(buildChild).toList(growable: false),
    );
  }
}
