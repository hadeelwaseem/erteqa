import 'package:flutter/material.dart';
import 'package:sooq_merchant/core/enums/card_style.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final CardStyleType? cardStyle;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.cardStyle,
  });

  BoxDecoration _getDecoration() {
    final style = cardStyle ?? CardStyleType.rounded;
    final borderRadius = switch (style) {
      CardStyleType.soft => BorderRadius.circular(20),
      CardStyleType.sharp => BorderRadius.zero,
      CardStyleType.outline => BorderRadius.circular(16),
      CardStyleType.flat => BorderRadius.circular(16),
      CardStyleType.rounded => BorderRadius.circular(16),
    };

    final boxShadow = switch (style) {
      CardStyleType.soft => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      CardStyleType.sharp => null,
      CardStyleType.outline => null,
      CardStyleType.flat => null,
      CardStyleType.rounded => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    };

    return BoxDecoration(
      color: style == CardStyleType.outline ? Colors.transparent : Colors.white,
      borderRadius: borderRadius,
      border: style == CardStyleType.outline
          ? Border.all(color: Colors.grey.shade300, width: 1)
          : null,
      boxShadow: boxShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _getDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE9EDF2),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize ?? 16,
              fontWeight: fontWeight ?? FontWeight.bold,
              color: textColor,
              fontStyle: fontStyle ?? FontStyle.normal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: (fontSize ?? 14) * 0.875,
              color: textColor?.withOpacity(0.7) ?? Colors.grey,
              fontStyle: fontStyle ?? FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}
