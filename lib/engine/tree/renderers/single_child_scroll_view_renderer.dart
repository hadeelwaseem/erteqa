import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../config/component_config.dart';
import '../../../core/enums/generic_component_type.dart';
import '../../component_renderer/component_renderer.dart';

class SingleChildScrollViewRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final axis = config.axis ?? config.properties['axis'] as String?;
    final scrollDirection = _parseAxis(axis);
    final childConfig = config.child;
    if (childConfig == null) return const SizedBox.shrink();

    if (_isScrollable(childConfig.type)) {
      if (kDebugMode) {
        return _nestedScrollWarning(
          'singleChildScrollView',
          childConfig.type.name,
        );
      }
      return buildChild(childConfig);
    }

    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      child: buildChild(childConfig),
    );
  }

  Axis _parseAxis(String? axis) {
    if (axis == 'horizontal') return Axis.horizontal;
    return Axis.vertical;
  }

  bool _isScrollable(GenericComponentType type) {
    return type == GenericComponentType.singleChildScrollView ||
        type == GenericComponentType.listView ||
        type == GenericComponentType.gridView;
  }

  Widget _nestedScrollWarning(String parent, String child) {
    return Center(
      child: Text(
        'Invalid nested scrollable: $parent -> $child',
        textAlign: TextAlign.center,
      ),
    );
  }
}
