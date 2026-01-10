
import 'package:flutter/material.dart';

class OrderTile extends StatelessWidget {
  final String status;
  final Color color;

  const OrderTile({super.key, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE9EDF2),
            child: Icon(Icons.receipt_long, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '\$20.00',
              style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),
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
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
