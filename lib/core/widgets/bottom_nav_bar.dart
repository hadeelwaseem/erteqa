import 'package:flutter/material.dart';
import 'package:sooq_merchant/core/widgets/active_nav_item.dart';
import 'package:sooq_merchant/features/customization/data/models/store_colors_model.dart';
import 'package:sooq_merchant/features/dashboard/widgets/top_bar.dart';

class BottomNavBar extends StatelessWidget {
  final StoreColorsModel colors;
  const BottomNavBar({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 72,
      child: Stack(
        children: [
          Positioned(
            left: 87,
            right: 0,
            child: Container(
              height: 72,
              padding: const EdgeInsets.only(left: 12, right: 12),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ActiveNavItem(label: 'Home'),
                  Icon(Icons.grid_view, color: Colors.white),
                  Icon(Icons.add, color: Colors.white, size: 30),
                  Icon(Icons.receipt_long, color: Colors.white),
                ],
              ),
            ),
          ),
          Positioned(
            left: 70,
            child: ClipPath(
              clipper: CurvedConnectorClipper(),
              child: Container(width: 20, height: 72, color: colors.primary),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
