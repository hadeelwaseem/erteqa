import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../actions/action_dispatcher.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/property_parsers.dart';

/// Collapsible section (FAQ, product details, settings groups).
///
/// Each instance is independent; multiple tiles may be expanded at once.
/// Optional [onExpansionChanged] merges `dataContext['tap'] = { expanded }`.
class ExpansionTileRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final properties = config.properties;
    final title = properties['title'] as String? ?? '';
    if (title.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = EngineTheme.fromDataContext(dataContext);
    final subtitle = properties['subtitle'] as String?;
    final initiallyExpanded = properties['initiallyExpanded'] == true;
    final maintainState = properties['maintainState'] != false;
    final enabled = properties['enabled'] != false;
    final showDivider = properties['showDivider'] == true;

    final backgroundColor =
        PropertyParsers.parseColor(properties['backgroundColor'] as String?) ??
        theme?.surfaceColor ??
        Colors.white;
    final collapsedBackgroundColor =
        PropertyParsers.parseColor(
          properties['collapsedBackgroundColor'] as String?,
        ) ??
        backgroundColor;
    final iconColor =
        PropertyParsers.parseColor(properties['iconColor'] as String?) ??
        theme?.mutedColor ??
        const Color(0xFF64748B);
    final textColor =
        PropertyParsers.parseColor(properties['textColor'] as String?) ??
        theme?.textColor ??
        const Color(0xFF0F172A);
    final subtitleColor =
        PropertyParsers.parseColor(properties['subtitleColor'] as String?) ??
        theme?.mutedColor ??
        const Color(0xFF475569);
    final dividerColor =
        PropertyParsers.parseColor(properties['dividerColor'] as String?) ??
        theme?.inputBorderColor ??
        const Color(0xFFE2E8F0);

    final tilePadding = PropertyParsers.parseEdgeInsets(
      properties['tilePadding'],
    );
    final childrenPadding =
        PropertyParsers.parseEdgeInsets(properties['childrenPadding']) ??
        const EdgeInsets.fromLTRB(16, 12, 16, 16);
    final borderRadius = PropertyParsers.parseBorderRadius(
      properties['borderRadius'],
    );

    final leadingIconName = properties['leadingIcon'] as String?;
    final trailingIconName = properties['trailingIcon'] as String?;

    final onExpansionChangedAction =
        properties['onExpansionChanged'] as Map<String, dynamic>?;

    final semanticsLabel = properties['semanticsLabel'] as String? ?? title;

    final bodyChildren = _resolveBodyChildren(config, buildChild, dataContext);
    if (bodyChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    final titleStyle = TextStyle(
      color: textColor,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = TextStyle(color: subtitleColor, fontSize: 13);

    const borderlessShape = Border();

    Widget tile = Builder(
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>('expansion_${config.hashCode}'),
            shape: borderlessShape,
            collapsedShape: borderlessShape,
            title: Text(title, style: titleStyle),
            subtitle: subtitle != null && subtitle.isNotEmpty
                ? Text(subtitle, style: subtitleStyle)
                : null,
            leading: leadingIconName != null
                ? Icon(
                    PropertyParsers.parseIconData(leadingIconName),
                    color: iconColor,
                  )
                : null,
            trailing: trailingIconName != null
                ? Icon(
                    PropertyParsers.parseIconData(trailingIconName),
                    color: iconColor,
                  )
                : null,

            initiallyExpanded: initiallyExpanded,
            maintainState: maintainState,
            enabled: enabled,
            tilePadding: tilePadding,
            childrenPadding: childrenPadding,
            backgroundColor: backgroundColor,
            collapsedBackgroundColor: collapsedBackgroundColor,
            iconColor: iconColor,
            collapsedIconColor: iconColor,
            children: bodyChildren,
            onExpansionChanged: (expanded) {
              final action = onExpansionChangedAction;
              if (action == null) return;
              final dispatcher = _resolveDispatcher(dataContext, context);
              if (dispatcher == null) return;
              final merged = Map<String, dynamic>.from(
                dataContext ?? <String, dynamic>{},
              );
              merged['tap'] = {'expanded': expanded};
              dispatcher.dispatch(action, dataContext: merged);
            },
          ),
        );
      },
    );

    if (borderRadius != null) {
      tile = ClipRRect(
        borderRadius: borderRadius,
        child: Material(color: backgroundColor, child: tile),
      );
    } else {
      tile = Material(color: backgroundColor, child: tile);
    }

    Widget result = tile;
    if (showDivider) {
      result = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          result,
          Divider(height: 1, thickness: 1, color: dividerColor),
        ],
      );
    }

    return Semantics(header: true, label: semanticsLabel, child: result);
  }

  List<Widget> _resolveBodyChildren(
    ComponentConfig config,
    ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  ) {
    final layoutChildren = config.layoutChildren;
    if (layoutChildren.isEmpty) return const [];

    return [for (final child in layoutChildren) buildChild(child)];
  }

  EngineActionDispatcher? _resolveDispatcher(
    Map<String, dynamic>? dataContext,
    BuildContext context,
  ) {
    if (dataContext != null) {
      final existing = dataContext[EngineActionDispatcher.contextKey];
      if (existing is EngineActionDispatcher) return existing;
    }
    final dispatcher = EngineActionDispatcher(context: context);
    dataContext?[EngineActionDispatcher.contextKey] = dispatcher;
    return dispatcher;
  }
}
