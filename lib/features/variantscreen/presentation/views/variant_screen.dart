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
/// 1. Receives a [variantId] (JSON file name) and an optional [pageRoute]
/// 2. Creates a [VariantCubit] to load the screen config
/// 3. Renders UI based on Cubit state:
///    - Loading: Shows progress indicator
///    - Success: Renders component tree via [ScreenRenderer]
///    - Failure: Shows error message
///
/// **Key**: Uses `ValueKey(pageRoute ?? variantId)` on the BlocProvider so
/// that go_router rebuilds and re-fetches when navigating to a different page
/// within the same JSON file (variantId unchanged, pageRoute changed).
///
/// **No outer Scaffold**: The Scaffold is provided by [TabShellWidget] via
/// ShellRoute. Adding another Scaffold here would cause nesting issues.
class VariantScreen extends StatelessWidget {
  const VariantScreen({
    super.key,
    required this.variantId,
    required this.variantRepository,
    this.pageRoute,
  });

  /// The JSON file identifier (e.g., 'mobile_component_flow_demo').
  final String variantId;

  /// Repository for loading screen configs from assets.
  final VariantRepository variantRepository;

  /// The route of the page within the JSON file (e.g., '/', '/products').
  final String? pageRoute;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('$variantId:${pageRoute ?? ""}'),
      create: (context) =>
          VariantCubit(variantRepository, variantId, pageRoute: pageRoute),
      child: BlocBuilder<VariantCubit, VariantState>(
        builder: (context, state) {
          return switch (state) {
            // Loading: Show spinner
            VariantInitial() || VariantLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            // Success: Render the component tree
            VariantSuccess(:final config) =>
              ScreenRenderer.withPrimitives().render(
                config,
                context: context,
              ),
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
    );
  }
}
