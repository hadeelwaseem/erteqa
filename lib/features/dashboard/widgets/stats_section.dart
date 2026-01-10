import 'package:flutter/material.dart';
import 'package:sooq_merchant/features/dashboard/widgets/stat_card.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> statsData = [
      {'icon': 'attach_money', 'value': '\$1400', 'label': "Today's Sales"},
      {'icon': 'receipt_long', 'value': '30', 'label': 'New Orders'},
      {
        'icon': 'inventory_2_outlined',
        'value': '1000',
        'label': 'Total Products',
      },
    ];

    return SizedBox(
      height: 140,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statsData.map((data) {
            IconData icon;
            switch (data['icon']) {
              case 'attach_money':
                icon = Icons.attach_money;
                break;
              case 'receipt_long':
                icon = Icons.receipt_long;
                break;
              case 'inventory_2_outlined':
                icon = Icons.inventory_2_outlined;
                break;
              case 'people':
                icon = Icons.people;
                break;
              default:
                icon = Icons.info;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 145,
                child: StatCard(
                  icon: icon,
                  value: data['value']!,
                  label: data['label']!,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
