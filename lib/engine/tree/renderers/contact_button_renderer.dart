import 'package:flutter/material.dart';

import '../../../config/component_config.dart';
import '../../component_renderer/component_renderer.dart';
import '../../theme/engine_theme.dart';
import '../parsers/data_context_path.dart';
import '../parsers/property_parsers.dart';
import 'button_label_row.dart';
import 'contact_channel_style.dart';

/// Contact-channel CTA (WhatsApp, tel, sms, email, url) with label + icon row.
class ContactButtonRenderer implements ComponentRenderer {
  @override
  Widget render(
    ComponentConfig config, {
    required ComponentWidgetBuilder buildChild,
    Map<String, dynamic>? dataContext,
  }) {
    final label = config.properties['label'] as String? ?? '';
    final channel = (config.properties['channel'] as String? ?? 'whatsapp')
        .toLowerCase();
    final channelStyle = ContactChannelStyle.forChannel(channel);
    final theme = EngineTheme.fromDataContext(dataContext);

    final backgroundColor = PropertyParsers.parseColor(
          config.properties['backgroundColor'] as String?,
        ) ??
        channelStyle.backgroundColor ??
        theme?.primaryColor;
    final foregroundColor = PropertyParsers.parseColor(
          config.properties['foregroundColor'] as String?,
        ) ??
        channelStyle.foregroundColor;

    final borderRadius = PropertyParsers.parseBorderRadius(
          config.properties['borderRadius'],
        ) ??
        BorderRadius.circular(10);
    final padding = PropertyParsers.parseEdgeInsets(
      config.properties['padding'],
    );
    final fullWidth = PropertyParsers.parseBool(
      config.properties['fullWidth'],
      defaultValue: true,
    );
    final onTap = config.properties['onTap'] as VoidCallback?;

    final staticTarget = config.properties['target'] as String?;
    final targetPath = config.properties['targetPath'] as String?;
    final resolvedTarget = _resolveTarget(
      staticTarget: staticTarget,
      targetPath: targetPath,
      dataContext: dataContext,
    );
    final hasTarget = resolvedTarget != null && resolvedTarget.isNotEmpty;
    final staticEnabled = PropertyParsers.parseBool(
      config.properties['enabled'],
      defaultValue: true,
    );
    final enabled = staticEnabled && hasTarget;
    final onPressed = enabled ? onTap : null;

    final labelStyle = TextStyle(
      color: foregroundColor,
      fontSize: PropertyParsers.parseDouble(config.properties['fontSize']) ?? 14,
      fontWeight: PropertyParsers.parseFontWeight(
        config.properties['fontWeight'] as String? ?? 'bold',
      ),
    );

    final buttonMd = theme?.buttonMd;
    final defaultPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: buttonMd?.padX ?? 16,
          vertical: 10,
        );
    final height = buttonMd?.height ?? 46;
    final minimumSize =
        fullWidth ? Size(double.infinity, height) : Size(64, height);

    final iconName =
        (config.properties['icon'] as String?)?.trim().isNotEmpty == true
            ? config.properties['icon'] as String
            : channelStyle.iconName;
    final iconSize = PropertyParsers.parseDouble(config.properties['iconSize']);
    final iconGap =
        PropertyParsers.parseDouble(config.properties['gap']) ??
        PropertyParsers.parseDouble(config.properties['iconGap']);

    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: defaultPadding,
        minimumSize: minimumSize,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: ButtonLabelRow.build(
        label: label,
        labelStyle: labelStyle,
        iconName: iconName,
        iconPosition:
            config.properties['iconPosition'] as String? ?? 'trailing',
        iconSize: iconSize,
        iconGap: iconGap,
        iconColor: foregroundColor,
      ),
    );

    Widget wrapped = button;
    if (fullWidth) {
      wrapped = SizedBox(width: double.infinity, child: wrapped);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: label.isNotEmpty ? label : null,
      child: wrapped,
    );
  }

  String? _resolveTarget({
    String? staticTarget,
    String? targetPath,
    Map<String, dynamic>? dataContext,
  }) {
    final direct = staticTarget?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    if (targetPath != null && targetPath.isNotEmpty) {
      return resolveDataContextPath(dataContext, targetPath)?.toString().trim();
    }
    return null;
  }
}
