import 'package:flutter/material.dart';

class ColorPickerTile extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ColorPickerTile({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
