import 'package:flutter/material.dart';
import '../domain/dashboard_data.dart';

abstract class DashboardDataProvider {
  String getWelcomeMessage();
  List<StatData> getStats();
  List<OrderData> getRecentOrders({int? maxItems});
  InsightsData getInsights();
}

class MockDashboardDataProvider implements DashboardDataProvider {
  @override
  String getWelcomeMessage() {
    return 'Welcome back, My Store !';
  }

  @override
  List<StatData> getStats() {
    return const [
      StatData(
        icon: Icons.attach_money,
        value: '\$1400',
        label: "Today's Sales",
      ),
      StatData(icon: Icons.receipt_long, value: '30', label: 'New Orders'),
      StatData(
        icon: Icons.inventory_2_outlined,
        value: '1000',
        label: 'Total Products',
      ),
    ];
  }

  @override
  List<OrderData> getRecentOrders({int? maxItems}) {
    final orders = const [
      OrderData(status: 'New', color: Colors.grey, amount: '\$20.00'),
      OrderData(
        status: 'Processing',
        color: Color(0xFFE7C99B),
        amount: '\$45.00',
      ),
      OrderData(
        status: 'Completed',
        color: Color(0xFF9BCBB8),
        amount: '\$120.00',
      ),
    ];

    if (maxItems != null && maxItems < orders.length) {
      return orders.take(maxItems).toList();
    }
    return orders;
  }

  @override
  InsightsData getInsights() {
    return const InsightsData(
      message:
          'Your Sales are up today 📈  Try adding more products to expand your store.',
      icon: Icons.trending_up,
    );
  }
}
