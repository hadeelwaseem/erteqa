import 'package:flutter/material.dart';
import 'package:sooq_merchant/core/enums/card_style.dart';

class OrderTile extends StatelessWidget {
  final String status;
  final Color color;
  final String? amount;
  final IconData? icon;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final CardStyleType? cardStyle;

  const OrderTile({
    super.key,
    required this.status,
    required this.color,
    this.amount,
    this.icon,
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
      padding: const EdgeInsets.all(12),
      decoration: _getDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE9EDF2),
            child: Icon(icon ?? Icons.receipt_long, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              amount ?? '\$20.00',
              style: TextStyle(
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight ?? FontWeight.w600,
                color: textColor,
                fontStyle: fontStyle ?? FontStyle.normal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: (fontSize ?? 12) * 0.75,
                color: textColor,
                fontStyle: fontStyle ?? FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
