import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/store_colors_model.dart';

void showJsonModal(BuildContext context, StoreColorsModel colors) {
  final jsonMap = {
    "primary": _hex(colors.primary),
    "background": _hex(colors.background),
    "button": _hex(colors.button),
    "secondary": _hex(colors.secondary),
    "success": _hex(colors.success),
    "text": _hex(colors.text),
  };

  final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Theme JSON (Preview)'),
      content: SelectableText(
        jsonString,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _hex(Color c) => '#${c.value.toRadixString(16).substring(2)}';
