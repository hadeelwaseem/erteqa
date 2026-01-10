import 'package:flutter/material.dart';

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.trending_up),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your Sales are up today 📈  Try adding more products to expand your store.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
