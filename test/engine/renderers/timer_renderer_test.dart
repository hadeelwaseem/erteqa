import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/tree/renderers/timer_renderer.dart';

import 'renderer_test_utils.dart';

class _RecordingDispatcher extends EngineActionDispatcher {
  _RecordingDispatcher({required super.context});

  int dispatchCount = 0;
  Map<String, dynamic>? lastAction;

  @override
  Future<void> dispatch(
    Map<String, dynamic> action, {
    String? value,
    String? fieldId,
    Map<String, dynamic>? dataContext,
  }) async {
    dispatchCount++;
    lastAction = action;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('timer dispatches navigate after durationMs', (tester) async {
    final renderer = TimerRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.timer,
      properties: {
        'durationMs': 50,
        'route': '/splash-carousel',
      },
    );

    late _RecordingDispatcher dispatcher;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dispatcher = _RecordingDispatcher(context: context);
            return renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...rendererDataContext(),
                EngineActionDispatcher.contextKey: dispatcher,
              },
            );
          },
        ),
      ),
    );

    expect(dispatcher.dispatchCount, 0);
    await tester.pump(const Duration(milliseconds: 60));
    expect(dispatcher.dispatchCount, 1);
    expect(dispatcher.lastAction?['type'], 'navigate');
    expect(dispatcher.lastAction?['route'], '/splash-carousel');
  });

  testWidgets('timer cancelled on dispose does not dispatch', (tester) async {
    final renderer = TimerRenderer();
    final config = ComponentConfig(
      type: GenericComponentType.timer,
      properties: {
        'durationMs': 200,
        'route': '/splash-carousel',
      },
    );

    late _RecordingDispatcher dispatcher;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dispatcher = _RecordingDispatcher(context: context);
            return renderer.render(
              config,
              buildChild: (_) => const SizedBox.shrink(),
              dataContext: {
                ...rendererDataContext(),
                EngineActionDispatcher.contextKey: dispatcher,
              },
            );
          },
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 250));
    expect(dispatcher.dispatchCount, 0);
  });
}
