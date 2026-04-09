import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sooq_merchant/engine/tree/tree_engine.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart';

/// Dynamic screen host widget.
///
/// **Responsibility**: Render a single dynamic screen (page) from a ScreenConfig.
///
/// **How it works**:
/// 1. Receives a [variantId] (pageId) from the router (e.g., `/variant/:id`)
/// 2. Creates a [VariantCubit] to load the screen config
/// 3. Renders UI based on Cubit state:
///    - Loading: Shows progress indicator
///    - Success: Renders component tree via [ScreenRenderer]
///    - Failure: Shows error message
///
/// **Pattern**: One instance per route navigation. Each pageId gets its own Cubit and loading flow.
///
/// **Not for nesting**: This is a route-level screen host. For nested content, use component tree.
class VariantScreen extends StatelessWidget {
  const VariantScreen({
    super.key,
    required this.variantId,
    required this.variantRepository,
  });

  /// The page ID to load (e.g., 'classic', 'dashboard', 'modern').
  /// Maps to JSON config file: `assets/config/{variantId}.json`
  final String variantId;

  /// Repository for loading screen configs from assets.
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
              // Render based on Cubit state
              return switch (state) {
                // Loading: Show spinner
                VariantInitial() || VariantLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                // Success: Render the component tree
                VariantSuccess(:final config) =>
                  ScreenRenderer.withPrimitives().render(config),
                // Failure: Show error message
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
