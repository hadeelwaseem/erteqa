import 'package:flutter/widgets.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/engine_theme.dart';
import 'skeleton_effect_factory.dart';
import 'skeleton_item_factory.dart';

/// Shared skeleton wrapper for request-bound list/grid initial loading.
class RequestBoundSkeleton {
  RequestBoundSkeleton._();

  static Map<String, dynamic> skeletonContext(Map<String, dynamic>? base) {
    if (base == null) {
      return {SkeletonItemFactory.skeletonModeKey: true};
    }
    return {...base, SkeletonItemFactory.skeletonModeKey: true};
  }

  static Widget wrap({
    required Widget child,
    Map<String, dynamic>? dataContext,
  }) {
    final theme = EngineTheme.fromDataContext(dataContext);
    return ExcludeSemantics(
      child: Skeletonizer(
        enabled: true,
        effect: SkeletonEffectFactory.shimmer(theme),
        containersColor: SkeletonEffectFactory.containersColor(theme),
        child: child,
      ),
    );
  }
}
