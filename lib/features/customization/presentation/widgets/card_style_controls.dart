import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/enums/card_style.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_cubit.dart';

class CardStyleControls extends StatelessWidget {
  const CardStyleControls({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<CustomizationPreviewCubit>();
    final currentStyle = cubit.state.layout.cardStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Card Style', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: CardStyleType.values.map((style) {
            final isSelected = style == currentStyle;
            return ChoiceChip(
              label: Text(style.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  cubit.updateCardStyle(style);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
