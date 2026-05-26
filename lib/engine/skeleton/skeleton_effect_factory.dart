import 'package:skeletonizer/skeletonizer.dart';

import '../theme/engine_theme.dart';

/// Maps [EngineTheme] colors to skeletonizer shimmer effects.
///
/// Prod theme uses very light surface/background (#F8FAFC / #F1F5F9); using
/// those directly as base/highlight makes the shimmer almost invisible.
class SkeletonEffectFactory {
  SkeletonEffectFactory._();

  /// Slate-300 — visible bone fill on light merchant backgrounds.
  static const Color kBoneBase = Color(0xFFCBD5E1);

  /// Near-white pulse on the shimmer pass.
  static const Color kBoneHighlight = Color(0xFFF8FAFC);

  /// Card/container fill while skeletonized (white JSON cards read as gray blocks).
  static const Color kContainerFill = Color(0xFFE2E8F0);

  static ShimmerEffect shimmer(EngineTheme? theme) {
    final background = theme?.backgroundColor ?? const Color(0xFFF1F5F9);
    // Slightly tune base to page background but keep strong contrast vs highlight.
    final base = Color.alphaBlend(
      kBoneBase.withValues(alpha: 0.85),
      background,
    );
    return ShimmerEffect(
      baseColor: base,
      highlightColor: kBoneHighlight,
      duration: const Duration(milliseconds: 1100),
    );
  }

  static Color containersColor(EngineTheme? theme) {
    final background = theme?.backgroundColor ?? const Color(0xFFF1F5F9);
    return Color.alphaBlend(
      kContainerFill.withValues(alpha: 0.9),
      background,
    );
  }
}
