import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Axis;

import '../../config/component_config.dart';
import '../../core/enums/generic_component_type.dart';
import '../../core/utils/app_logger.dart';

/// Describes a layout contract violation detected before render.
class LayoutViolation {
  const LayoutViolation({
    required this.path,
    required this.code,
    required this.message,
    this.severity = LayoutViolationSeverity.warning,
  });

  final String path;
  final String code;
  final String message;
  final LayoutViolationSeverity severity;
}

enum LayoutViolationSeverity { warning, error }

/// Thrown when [LayoutConstraintValidator.validateOrThrow] finds error-severity issues.
class LayoutConstraintException implements Exception {
  LayoutConstraintException(this.violations);

  final List<LayoutViolation> violations;

  @override
  String toString() {
    final errors = violations
        .where((v) => v.severity == LayoutViolationSeverity.error)
        .map((v) => '${v.code} at ${v.path}: ${v.message}')
        .join('; ');
    return 'LayoutConstraintException: $errors';
  }
}

/// Parse-time validator for JSON layout trees.
///
/// Walks [ComponentConfig] and flags combinations that commonly cause overflow,
/// unbounded flex, or misleading viewport-centering in production JSON.
class LayoutConstraintValidator {
  const LayoutConstraintValidator();

  /// Short static auth forms allowed with `scroll: none` and no inner scroll.
  static const authStaticScrollNoneRoutes = {
    '/auth/login',
    '/auth/otp-reset',
  };

  List<LayoutViolation> validate(
    ComponentConfig root, {
    String? pageScroll,
    String? pageLayout,
    String? pageRoute,
  }) {
    final resolvedScroll = pageScroll ?? _pageScrollFromRoot(root);
    final resolvedLayout = pageLayout ?? _pageLayoutFromRoot(root);
    final resolvedRoute = pageRoute ?? root.properties['pageRoute'] as String?;

    final violations = <LayoutViolation>[];
    _walk(
      root,
      path: 'root',
      pageScroll: resolvedScroll,
      pageLayout: resolvedLayout,
      pageRoute: resolvedRoute,
      parentFlexAxis: null,
      parentMainAxisSizeMin: false,
      insideScrollable: false,
      violations: violations,
    );
    return violations;
  }

  /// Logs violations; throws [LayoutConstraintException] when [throwOnError] and errors exist.
  static void reportViolations(
    List<LayoutViolation> violations, {
    bool throwOnError = false,
  }) {
    for (final issue in violations) {
      final line =
          '[LayoutConstraintValidator] ${issue.severity.name} '
          '${issue.code} at ${issue.path}: ${issue.message}';
      if (issue.severity == LayoutViolationSeverity.warning) {
        AppLogger.warning(line);
      } else {
        AppLogger.warning(line);
      }
    }
    if (throwOnError &&
        violations.any((i) => i.severity == LayoutViolationSeverity.error)) {
      throw LayoutConstraintException(violations);
    }
  }

  /// Validates and throws on error-severity violations (tests / strict mode).
  void validateOrThrow(
    ComponentConfig root, {
    String? pageScroll,
    String? pageLayout,
    String? pageRoute,
  }) {
    final violations = validate(
      root,
      pageScroll: pageScroll,
      pageLayout: pageLayout,
      pageRoute: pageRoute,
    );
    reportViolations(violations, throwOnError: true);
  }

  String _pageScrollFromRoot(ComponentConfig root) {
    if (root.type == GenericComponentType.scaffold) {
      return root.properties['pageScroll'] as String? ?? 'vertical';
    }
    return 'vertical';
  }

  String? _pageLayoutFromRoot(ComponentConfig root) {
    if (root.type == GenericComponentType.scaffold) {
      return root.properties['pageLayout'] as String?;
    }
    return null;
  }

  bool _isCenteredLayout(String? pageLayout) => pageLayout == 'centered';

  bool _isExemptFromStaticOverflow({
    required String? pageLayout,
    required String? pageRoute,
  }) {
    if (_isCenteredLayout(pageLayout)) return true;
    if (pageRoute != null && authStaticScrollNoneRoutes.contains(pageRoute)) {
      return true;
    }
    return false;
  }

  void _walk(
    ComponentConfig config, {
    required String path,
    required String pageScroll,
    required String? pageLayout,
    required String? pageRoute,
    required Axis? parentFlexAxis,
    required bool parentMainAxisSizeMin,
    required bool insideScrollable,
    required List<LayoutViolation> violations,
  }) {
    final type = config.type;
    final props = config.properties;

    if (type == GenericComponentType.spacer) {
      if (parentFlexAxis == null) {
        violations.add(
          LayoutViolation(
            path: path,
            code: 'spacer_outside_flex',
            message:
                'spacer requires a Row/Column Flex parent; use gap on column/row '
                'or fixed container height instead.',
            severity: LayoutViolationSeverity.error,
          ),
        );
      } else if (parentMainAxisSizeMin &&
          parentFlexAxis == Axis.vertical) {
        violations.add(
          LayoutViolation(
            path: path,
            code: 'spacer_in_min_column',
            message:
                'spacer inside column with mainAxisSize min will overflow; '
                'use gap or mainAxisSize max.',
            severity: LayoutViolationSeverity.error,
          ),
        );
      }
    }

    if (type == GenericComponentType.container && props['expand'] == true) {
      if (insideScrollable &&
          pageScroll == 'vertical' &&
          !_subtreeHasExpandAwareColumn(config)) {
        violations.add(
          LayoutViolation(
            path: path,
            code: 'expand_in_scroll_without_contract',
            message:
                'container.expand under page scroll:vertical relies on scaffold '
                'minHeight hack; prefer scroll:none for full viewport layouts.',
            severity: LayoutViolationSeverity.warning,
          ),
        );
      }
    }

    if (type == GenericComponentType.column) {
      final mainAxisSize = props['mainAxisSize'] as String? ?? 'min';
      final mainAxisAlignment = props['mainAxisAlignment'] as String?;
      if (mainAxisSize == 'max' &&
          mainAxisAlignment == 'center' &&
          pageScroll == 'vertical' &&
          !_isCenteredLayout(pageLayout) &&
          !_columnHasExpandChild(config)) {
        violations.add(
          LayoutViolation(
            path: path,
            code: 'viewport_center_without_expand',
            message:
                'column mainAxisAlignment center + mainAxisSize max under '
                'scroll:vertical without container.expand will center within '
                'content height, not the viewport.',
            severity: LayoutViolationSeverity.error,
          ),
        );
      }
    }

    if (type == GenericComponentType.singleChildScrollView && insideScrollable) {
      violations.add(
        LayoutViolation(
          path: path,
          code: 'nested_scrollable',
          message:
              'singleChildScrollView nested inside another scrollable causes '
              'nested scroll / gesture conflicts.',
          severity: LayoutViolationSeverity.warning,
        ),
      );
    }

    if (pageScroll == 'none' &&
        type == GenericComponentType.scaffold &&
        _bodyMayOverflowWithoutInnerScroll(config) &&
        !_isExemptFromStaticOverflow(
          pageLayout: pageLayout,
          pageRoute: pageRoute,
        )) {
      violations.add(
        LayoutViolation(
          path: path,
          code: 'static_page_overflow_risk',
          message:
              'scroll:none page without inner list/grid/singleChildScrollView '
              'may overflow on small viewports.',
          severity: LayoutViolationSeverity.error,
        ),
      );
    }

    final nextInsideScrollable = insideScrollable ||
        type == GenericComponentType.singleChildScrollView ||
        (type == GenericComponentType.scaffold &&
            pageScroll == 'vertical');

    Axis? childFlexAxis;
    var childMainAxisSizeMin = false;
    if (type == GenericComponentType.column) {
      childFlexAxis = Axis.vertical;
      childMainAxisSizeMin =
          (props['mainAxisSize'] as String? ?? 'min') == 'min';
    } else if (type == GenericComponentType.row) {
      childFlexAxis = Axis.horizontal;
      childMainAxisSizeMin =
          (props['mainAxisSize'] as String? ?? 'max') == 'min';
    }

    if (config.child != null) {
      _walk(
        config.child!,
        path: '$path.child',
        pageScroll: pageScroll,
        pageLayout: pageLayout,
        pageRoute: pageRoute,
        parentFlexAxis: childFlexAxis,
        parentMainAxisSizeMin: childMainAxisSizeMin,
        insideScrollable: nextInsideScrollable,
        violations: violations,
      );
    }

    final children = config.children;
    if (children != null) {
      for (var i = 0; i < children.length; i++) {
        _walk(
          children[i],
          path: '$path.children[$i]',
          pageScroll: pageScroll,
          pageLayout: pageLayout,
          pageRoute: pageRoute,
          parentFlexAxis: childFlexAxis,
          parentMainAxisSizeMin: childMainAxisSizeMin,
          insideScrollable: nextInsideScrollable,
          violations: violations,
        );
      }
    }

    final item = config.itemBuilder?.item;
    if (item != null) {
      _walk(
        item,
        path: '$path.itemBuilder.item',
        pageScroll: pageScroll,
        pageLayout: pageLayout,
        pageRoute: pageRoute,
        parentFlexAxis: null,
        parentMainAxisSizeMin: false,
        insideScrollable: nextInsideScrollable,
        violations: violations,
      );
    }
  }

  bool _columnHasExpandChild(ComponentConfig column) {
    for (final c in column.children ?? const <ComponentConfig>[]) {
      if (c.type == GenericComponentType.container &&
          c.properties['expand'] == true) {
        return true;
      }
    }
    return false;
  }

  bool _subtreeHasExpandAwareColumn(ComponentConfig node) {
    if (node.type == GenericComponentType.column &&
        node.properties['mainAxisSize'] == 'max') {
      return true;
    }
    if (node.child != null && _subtreeHasExpandAwareColumn(node.child!)) {
      return true;
    }
    for (final c in node.children ?? const <ComponentConfig>[]) {
      if (_subtreeHasExpandAwareColumn(c)) return true;
    }
    return false;
  }

  bool _bodyMayOverflowWithoutInnerScroll(ComponentConfig scaffold) {
    final column = scaffold.child;
    if (column == null) return false;
    return !_subtreeHasScrollable(column);
  }

  bool _subtreeHasScrollable(ComponentConfig node) {
    if (node.type == GenericComponentType.listView ||
        node.type == GenericComponentType.gridView ||
        node.type == GenericComponentType.singleChildScrollView) {
      return true;
    }
    if (node.properties['enableInnerScroll'] == true) return true;
    if (node.child != null && _subtreeHasScrollable(node.child!)) return true;
    for (final c in node.children ?? const <ComponentConfig>[]) {
      if (_subtreeHasScrollable(c)) return true;
    }
    return false;
  }

  /// Logs violations in debug builds (secondary guard). Does not throw.
  static bool reportIfNeeded(
    ComponentConfig root, {
    String? pageScroll,
    String? pageLayout,
    String? pageRoute,
  }) {
    if (!kDebugMode) return false;
    final issues = const LayoutConstraintValidator().validate(
      root,
      pageScroll: pageScroll,
      pageLayout: pageLayout,
      pageRoute: pageRoute,
    );
    reportViolations(issues);
    return issues.any((i) => i.severity == LayoutViolationSeverity.error);
  }
}

/// Returns true when any node in [nodes] has `container` with `expand: true`.
bool layoutSubtreeHasExpandContainer(Iterable<ComponentConfig> nodes) {
  for (final node in nodes) {
    if (_nodeHasExpandContainer(node)) return true;
  }
  return false;
}

bool _nodeHasExpandContainer(ComponentConfig config) {
  if (config.type == GenericComponentType.container &&
      config.properties['expand'] == true) {
    return true;
  }
  if (config.child != null && _nodeHasExpandContainer(config.child!)) {
    return true;
  }
  for (final c in config.children ?? const <ComponentConfig>[]) {
    if (_nodeHasExpandContainer(c)) return true;
  }
  return false;
}
