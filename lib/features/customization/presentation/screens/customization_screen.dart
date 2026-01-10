import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_cubit.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_cubit.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_state.dart';
import 'package:sooq_merchant/features/customization/presentation/widgets/card_style_controls.dart';
import 'package:sooq_merchant/features/customization/presentation/widgets/json_modal.dart';
import 'package:sooq_merchant/features/customization/presentation/widgets/color_controls.dart';
import 'package:sooq_merchant/features/customization/presentation/widgets/dashboard_preview.dart';
import 'package:sooq_merchant/features/customization/data/models/store_layout_model.dart';

class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomizationPreviewCubit(
        colors: context.read<CustomizationCubit>().state,
        layout: StoreLayoutModel.defaultLayout(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customize Store'),
          actions: [
            BlocBuilder<CustomizationPreviewCubit, CustomizationPreviewState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: () => showJsonModal(context, state.colors),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: const [
            Expanded(flex: 6, child: DashboardPreview()),
            Divider(height: 1),
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ColorControls(),
                      SizedBox(height: 16),
                      CardStyleControls(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
