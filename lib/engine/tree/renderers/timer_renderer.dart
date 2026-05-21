import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../actions/action_dispatcher.dart';
import '../../component_renderer/component_renderer.dart';

/// Invisible one-shot delay that dispatches a navigate action when elapsed.
///
/// JSON `props`:
/// - `durationMs` (required)
/// - `route` — shorthand for `tap: { type: navigate, route }`
/// - `tap` — optional full action map (v1: navigate)
class TimerRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final durationMs =
        _parseDurationMs(config.properties['durationMs']) ?? 0;
    final action = _resolveAction(config.properties);

    return _EngineTimer(
      durationMs: durationMs,
      action: action,
      dataContext: dataContext,
    );
  }

  int? _parseDurationMs(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic>? _resolveAction(Map<String, dynamic> properties) {
    final tap = properties['tap'];
    if (tap is Map) {
      return Map<String, dynamic>.from(tap);
    }
    final route = properties['route'] as String?;
    if (route != null && route.isNotEmpty) {
      return {'type': 'navigate', 'route': route};
    }
    return null;
  }
}

class _EngineTimer extends StatefulWidget {
  const _EngineTimer({
    required this.durationMs,
    required this.action,
    this.dataContext,
  });

  final int durationMs;
  final Map<String, dynamic>? action;
  final Map<String, dynamic>? dataContext;

  @override
  State<_EngineTimer> createState() => _EngineTimerState();
}

class _EngineTimerState extends State<_EngineTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.durationMs <= 0 || widget.action == null) return;
    _timer = Timer(
      Duration(milliseconds: widget.durationMs),
      _fire,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fire() {
    if (!mounted) return;
    final dispatcher = widget.dataContext?[EngineActionDispatcher.contextKey];
    if (dispatcher is! EngineActionDispatcher) return;
    final action = widget.action;
    if (action == null) return;
    dispatcher.dispatch(action, dataContext: widget.dataContext);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
