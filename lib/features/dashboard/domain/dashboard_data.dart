import 'package:flutter/material.dart';

/// Container for dashboard screen data (from backend/API or mock provider).
class DashboardData {
  final String welcomeMessage;
  final List<StatData> stats;
  final List<OrderData> recentOrders;
  final InsightsData insights;

  const DashboardData({
    required this.welcomeMessage,
    required this.stats,
    required this.recentOrders,
    required this.insights,
  });
}

class StatData {
  final IconData icon;
  final String value;
  final String label;

  const StatData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class OrderData {
  final String status;
  final Color color;
  final String amount;
  final IconData? icon;

  const OrderData({
    required this.status,
    required this.color,
    required this.amount,
    this.icon,
  });
}

class InsightsData {
  final String message;
  final IconData icon;

  const InsightsData({required this.message, this.icon = Icons.trending_up});
}
