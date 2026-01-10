import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_cubit.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_state.dart';
import 'package:sooq_merchant/features/dashboard/widgets/dashboard_view.dart';

class DashboardPreview extends StatelessWidget {
  const DashboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<CustomizationPreviewCubit, CustomizationPreviewState>(
        builder: (context, previewState) {
          final previewColors = previewState.colors;
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DashboardView(colors: previewColors, showBottomNav: true),
            ),
          );
        },
      ),
    );
  }
}
