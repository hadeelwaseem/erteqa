import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/tree/renderers/column_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/container_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/scaffold_renderer.dart';
import 'package:sooq_merchant/engine/tree/renderers/text_renderer.dart';

import 'renderer_test_utils.dart';

/// Builds a minimal subtree with column, container, scaffold, text renderers.
Widget buildLayoutTree(
  ComponentConfig root, {
  Map<String, dynamic>? dataContext,
}) {
  final ctx = dataContext ?? rendererDataContext();

  Widget buildChild(ComponentConfig child) {
    switch (child.type) {
      case GenericComponentType.scaffold:
        return ScaffoldRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: ctx,
        );
      case GenericComponentType.column:
        return ColumnRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: ctx,
        );
      case GenericComponentType.container:
        return ContainerRenderer().render(
          child,
          buildChild: buildChild,
          dataContext: ctx,
        );
      default:
        return TextRenderer().render(
          child,
          buildChild: (_) => const SizedBox.shrink(),
          dataContext: ctx,
        );
    }
  }

  return buildChild(root);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewport = Size(360, 640);

  Future<void> pumpTree(
    WidgetTester tester,
    ComponentConfig root,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: viewport),
          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: buildLayoutTree(root),
          ),
        ),
      ),
    );
    final exception = tester.takeException();
    if (exception != null) {
      expect(
        exception.toString(),
        isNot(contains('RenderFlex')),
        reason: exception.toString(),
      );
      expect(
        exception.toString(),
        isNot(contains('unbounded')),
        reason: exception.toString(),
      );
    }
  }

  group('scroll vertical', () {
    testWidgets('min column start — no flex exception', (tester) async {
      await pumpTree(
        tester,
        ComponentConfig(
          type: GenericComponentType.scaffold,
          properties: const {'pageScroll': 'vertical'},
          child: ComponentConfig(
            type: GenericComponentType.column,
            properties: const {'mainAxisSize': 'min'},
            children: [
              ComponentConfig(
                type: GenericComponentType.text,
                properties: {'value': 'a'},
              ),
            ],
          ),
        ),
      );
      expect(find.text('a'), findsOneWidget);
    });

    testWidgets('max column center without expand — content not viewport centered',
        (tester) async {
      await pumpTree(
        tester,
        ComponentConfig(
          type: GenericComponentType.scaffold,
          properties: const {'pageScroll': 'vertical'},
          child: ComponentConfig(
            type: GenericComponentType.column,
            properties: const {
              'mainAxisSize': 'max',
              'mainAxisAlignment': 'center',
            },
            children: [
              ComponentConfig(
                type: GenericComponentType.text,
                properties: {'value': 'top-heavy'},
              ),
            ],
          ),
        ),
      );
      final offset = tester.getTopLeft(find.text('top-heavy'));
      expect(offset.dy, lessThan(200));
    });

    testWidgets('expand under vertical scroll — no flex exception', (
      tester,
    ) async {
      await pumpTree(
        tester,
        ComponentConfig(
          type: GenericComponentType.scaffold,
          properties: const {'pageScroll': 'vertical'},
          child: ComponentConfig(
            type: GenericComponentType.column,
            properties: const {
              'mainAxisSize': 'max',
              'crossAxisAlignment': 'stretch',
            },
            children: [
              ComponentConfig(
                type: GenericComponentType.container,
                properties: const {'expand': true},
                child: ComponentConfig(
                  type: GenericComponentType.column,
                  properties: const {
                    'mainAxisSize': 'max',
                    'mainAxisAlignment': 'center',
                  },
                  children: [
                    ComponentConfig(
                      type: GenericComponentType.text,
                      properties: {'value': 'centered'},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('centered'), findsOneWidget);
      // Viewport centering under scroll:vertical is PARTIAL (see LAYOUT_CONSTRAINT_AUDIT.md).
    });
  });

  group('scroll none', () {
    testWidgets('expand fill + center column', (tester) async {
      await pumpTree(
        tester,
        ComponentConfig(
          type: GenericComponentType.scaffold,
          properties: const {'pageScroll': 'none'},
          child: ComponentConfig(
            type: GenericComponentType.column,
            properties: const {
              'mainAxisSize': 'max',
              'crossAxisAlignment': 'stretch',
            },
            children: [
              ComponentConfig(
                type: GenericComponentType.container,
                properties: const {'expand': true},
                child: ComponentConfig(
                  type: GenericComponentType.column,
                  properties: const {
                    'mainAxisSize': 'max',
                    'mainAxisAlignment': 'center',
                  },
                  children: [
                    ComponentConfig(
                      type: GenericComponentType.text,
                      properties: {'value': 'splash-center'},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      final offset = tester.getTopLeft(find.text('splash-center'));
      expect(offset.dy, greaterThan(150));
      expect(offset.dy, lessThan(500));
      expect(find.byType(Expanded), findsWidgets);
    });

    testWidgets('auth-style center column with single child renders content', (
      tester,
    ) async {
      await pumpTree(
        tester,
        ComponentConfig(
          type: GenericComponentType.scaffold,
          properties: const {
            'pageScroll': 'none',
            'pageLayout': 'centered',
          },
          child: ComponentConfig(
            type: GenericComponentType.column,
            properties: const {
              'mainAxisSize': 'max',
              'crossAxisAlignment': 'stretch',
            },
            children: [
              ComponentConfig(
                type: GenericComponentType.container,
                properties: const {'expand': true},
                child: ComponentConfig(
                  type: GenericComponentType.column,
                  properties: const {
                    'mainAxisSize': 'max',
                    'mainAxisAlignment': 'center',
                    'crossAxisAlignment': 'stretch',
                  },
                  child: ComponentConfig(
                    type: GenericComponentType.text,
                    properties: {'value': 'أدخل رقم جوالك'},
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('أدخل رقم جوالك'), findsOneWidget);
    });

    testWidgets('center column scrolls when content exceeds keyboard viewport', (
      tester,
    ) async {
      const keyboardViewport = Size(360, 408);

      ComponentConfig sizedBox(double height) => ComponentConfig(
            type: GenericComponentType.container,
            properties: {'height': height},
          );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: keyboardViewport),
            child: SizedBox(
              width: keyboardViewport.width,
              height: keyboardViewport.height,
              child: buildLayoutTree(
                ComponentConfig(
                  type: GenericComponentType.scaffold,
                  properties: const {'pageScroll': 'none'},
                  child: ComponentConfig(
                    type: GenericComponentType.column,
                    properties: const {
                      'mainAxisSize': 'max',
                      'crossAxisAlignment': 'stretch',
                    },
                    children: [
                      ComponentConfig(
                        type: GenericComponentType.container,
                        properties: const {'expand': true},
                        child: ComponentConfig(
                          type: GenericComponentType.column,
                          properties: const {
                            'mainAxisSize': 'max',
                            'mainAxisAlignment': 'center',
                            'crossAxisAlignment': 'stretch',
                            'gap': 16,
                          },
                          children: [
                            sizedBox(120),
                            sizedBox(41),
                            sizedBox(24),
                            sizedBox(48),
                            sizedBox(48),
                            sizedBox(56),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
