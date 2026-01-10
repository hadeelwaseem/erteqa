import 'package:flutter/material.dart';
import 'package:sooq_merchant/core/widgets/bottom_nav_bar.dart';
import 'package:sooq_merchant/features/customization/data/models/store_colors_model.dart';
import 'package:sooq_merchant/features/dashboard/widgets/insights_card.dart';
import 'package:sooq_merchant/features/dashboard/widgets/recent_orders_section.dart';
import 'package:sooq_merchant/features/dashboard/widgets/stats_section.dart';
import 'package:sooq_merchant/features/dashboard/widgets/top_bar.dart';
import 'package:sooq_merchant/features/dashboard/widgets/welcome_text.dart';

class DashboardView extends StatelessWidget {
  final StoreColorsModel colors;
  final bool showBottomNav;

  const DashboardView({
    super.key,
    required this.colors,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: showBottomNav ? BottomNavBar(colors: colors) : null,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(),
              SizedBox(height: 20),
              WelcomeText(text: 'Welcome back, My Store !'),
              SizedBox(height: 20),
              StatsSection(),
              SizedBox(height: 20),
              InsightsCard(),
              SizedBox(height: 24),
              RecentOrdersSection(),
            ],
          ),
        ),
      ),
    );
  }
}
