import 'package:flutter/material.dart';
import 'package:sooq_merchant/features/dashboard/widgets/order_tile.dart';

class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Recent Orders',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        OrderTile(status: 'New', color: Colors.grey),
        SizedBox(height: 8),
        OrderTile(status: 'Processing', color: Color(0xFFE7C99B)),
        SizedBox(height: 8),
        OrderTile(status: 'Completed', color: Color(0xFF9BCBB8)),
      ],
    );
  }
}
