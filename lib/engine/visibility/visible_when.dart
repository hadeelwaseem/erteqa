import 'package:flutter/widgets.dart';

import '../form/form_state_store.dart';
import '../page/page_state_store.dart';

/// Parsed `props.visibleWhen` — show child only when a form/pageState field
/// matches [when] (`isEmpty` | `nonEmpty`).
class VisibleWhenSpec {
  const VisibleWhenSpec({
    required this.source,
    required this.field,
    required this.when,
  });

  final String source;
  final String field;
  final String when;

  static VisibleWhenSpec? tryParse(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final field = raw['field'] as String?;
    if (field == null || field.isEmpty) {
      return null;
    }
    final source = (raw['source'] as String?)?.toLowerCase() ?? 'form';
    final when = (raw['when'] as String?)?.toLowerCase() ?? 'nonempty';
    return VisibleWhenSpec(source: source, field: field, when: when);
  }

  bool evaluate({
    FormStateStore? formState,
    PageStateStore? pageStateStore,
  }) {
    final text = _resolveValue(
      formState: formState,
      pageStateStore: pageStateStore,
    );
    final isEmpty = text == null || text.trim().isEmpty;
    return switch (when) {
      'isempty' => isEmpty,
      'nonempty' => !isEmpty,
      _ => !isEmpty,
    };
  }

  String? _resolveValue({
    FormStateStore? formState,
    PageStateStore? pageStateStore,
  }) {
    switch (source) {
      case 'form':
        if (formState == null) {
          return null;
        }
        final stored = formState.valueFor(field);
        if (stored != null) {
          return stored;
        }
        return formState.controllerFor(field).text;
      case 'pagestate':
      case 'page_state':
        final value = pageStateStore?.values[field];
        if (value == null) {
          return null;
        }
        return value.toString();
      default:
        return null;
    }
  }
}

/// Wraps [child] when [visibleWhenRaw] is set; otherwise returns [child] unchanged.
Widget wrapWithVisibleWhen({
  required Widget child,
  required Map<String, dynamic>? dataContext,
  required dynamic visibleWhenRaw,
}) {
  final spec = VisibleWhenSpec.tryParse(visibleWhenRaw);
  if (spec == null) {
    return child;
  }

  final formState =
      dataContext?[FormStateStore.contextKey] as FormStateStore?;
  final pageStateStore =
      dataContext?[PageStateStore.contextKey] as PageStateStore?;

  if (spec.source == 'form') {
    if (formState == null) {
      return child;
    }
    return ListenableBuilder(
      listenable: formState.controllerFor(spec.field),
      builder: (context, _) {
        if (spec.evaluate(
          formState: formState,
          pageStateStore: pageStateStore,
        )) {
          return child;
        }
        return const SizedBox.shrink();
      },
    );
  }

  // pageState: VariantScreen already setState's on PageStateStore.onChanged.
  if (spec.evaluate(formState: formState, pageStateStore: pageStateStore)) {
    return child;
  }
  return const SizedBox.shrink();
}
