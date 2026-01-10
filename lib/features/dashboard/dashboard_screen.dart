import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/customization/data/models/store_colors_model.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_cubit.dart';
import 'package:sooq_merchant/features/dashboard/widgets/dashboard_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomizationCubit, StoreColorsModel>(
      builder: (context, colors) {
        return DashboardView(colors: colors);
      },
    );
  }
}
