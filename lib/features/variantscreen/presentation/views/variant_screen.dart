import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sooq_merchant/engine/tree/tree_engine.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart';

class VariantScreen extends StatelessWidget {
  const VariantScreen({
    super.key,
    required this.variantId,
    required this.variantRepository,
  });

  final String variantId;
  final VariantRepository variantRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VariantCubit(variantRepository, variantId),
      child: SafeArea(
        child: Scaffold(
          // appBar: AppBar(
          //   title: Text('Variant: $variantId'),
          // ),
          body: BlocBuilder<VariantCubit, VariantState>(
            builder: (context, state) {
              return switch (state) {
                VariantInitial() || VariantLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                VariantSuccess(:final config) =>
                  ScreenRenderer.withPrimitives().render(config),
                VariantFailure(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}
