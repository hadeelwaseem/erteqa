import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/config/component_config.dart';
import 'package:sooq_merchant/core/enums/generic_component_type.dart';
import 'package:sooq_merchant/engine/validation/layout_constraint_validator.dart';

void main() {
  const validator = LayoutConstraintValidator();

  test('errors viewport center without expand under vertical scroll', () {
    final root = ComponentConfig(
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
            properties: {'value': 'x'},
          ),
        ],
      ),
    );
    final issues = validator.validate(root);
    final match = issues.where((i) => i.code == 'viewport_center_without_expand');
    expect(match, isNotEmpty);
    expect(match.first.severity, LayoutViolationSeverity.error);
  });

  test('no viewport center error when expand child present', () {
    final root = ComponentConfig(
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
            type: GenericComponentType.container,
            properties: const {'expand': true},
            child: ComponentConfig(
              type: GenericComponentType.text,
              properties: {'value': 'x'},
            ),
          ),
        ],
      ),
    );
    final issues = validator.validate(root);
    expect(
      issues.any((i) => i.code == 'viewport_center_without_expand'),
      isFalse,
    );
  });

  test('centered layout exempts viewport center error', () {
    final root = ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: const {'pageScroll': 'vertical', 'pageLayout': 'centered'},
      child: ComponentConfig(
        type: GenericComponentType.column,
        properties: const {
          'mainAxisSize': 'max',
          'mainAxisAlignment': 'center',
        },
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'x'},
          ),
        ],
      ),
    );
    final issues = validator.validate(root, pageLayout: 'centered');
    expect(
      issues.any((i) => i.code == 'viewport_center_without_expand'),
      isFalse,
    );
  });

  test('errors static overflow on scroll none without exemption', () {
    final root = ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: const {'pageScroll': 'none'},
      child: ComponentConfig(
        type: GenericComponentType.column,
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'tall'},
          ),
        ],
      ),
    );
    final issues = validator.validate(root, pageScroll: 'none');
    final match = issues.where((i) => i.code == 'static_page_overflow_risk');
    expect(match, isNotEmpty);
    expect(match.first.severity, LayoutViolationSeverity.error);
  });

  test('auth route whitelist exempts static overflow', () {
    final root = ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: const {'pageScroll': 'none'},
      child: ComponentConfig(
        type: GenericComponentType.column,
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'form'},
          ),
        ],
      ),
    );
    final issues = validator.validate(
      root,
      pageScroll: 'none',
      pageRoute: '/auth/login',
    );
    expect(
      issues.any((i) => i.code == 'static_page_overflow_risk'),
      isFalse,
    );
  });

  test('centered layout exempts static overflow', () {
    final root = ComponentConfig(
      type: GenericComponentType.scaffold,
      properties: const {'pageScroll': 'none', 'pageLayout': 'centered'},
      child: ComponentConfig(
        type: GenericComponentType.column,
        children: [
          ComponentConfig(
            type: GenericComponentType.text,
            properties: {'value': 'splash'},
          ),
        ],
      ),
    );
    final issues = validator.validate(
      root,
      pageScroll: 'none',
      pageLayout: 'centered',
    );
    expect(
      issues.any((i) => i.code == 'static_page_overflow_risk'),
      isFalse,
    );
  });

  test('validateOrThrow throws on error severity', () {
    final root = ComponentConfig(
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
            properties: {'value': 'x'},
          ),
        ],
      ),
    );
    expect(
      () => validator.validateOrThrow(root),
      throwsA(isA<LayoutConstraintException>()),
    );
  });
}
