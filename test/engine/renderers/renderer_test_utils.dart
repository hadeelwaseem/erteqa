import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/config/models/mobile_theme_config.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';

Map<String, dynamic> rendererDataContext() {
  return {
    EngineTheme.contextKey: EngineTheme.fromConfig(MobileThemeConfig.defaults()),
  };
}

Map<String, dynamic> formRendererDataContext() {
  return {
    ...rendererDataContext(),
    FormStateStore.contextKey: FormStateStore(),
  };
}

/// Request-bound list/grid: initial load in progress.
Map<String, dynamic> requestLoadingDataContext(String requestKey) {
  return {
    ...rendererDataContext(),
    'loadingRequestKeys': {requestKey: true},
  };
}

/// Request-bound list/grid: success with items under `requests[key].data`.
Map<String, dynamic> requestReadyDataContext({
  required String requestKey,
  required List<Map<String, dynamic>> items,
}) {
  return {
    ...rendererDataContext(),
    'requests': {
      requestKey: {'success': true, 'data': items},
    },
  };
}

/// Merges [ComponentConfig.dataContextOverride] like [ScreenRenderer].
Map<String, dynamic> mergeRendererContext(
  Map<String, dynamic> base,
  ComponentConfig config,
) {
  final override = config.dataContextOverride;
  if (override == null || override.isEmpty) {
    return base;
  }
  return {...base, ...override};
}
