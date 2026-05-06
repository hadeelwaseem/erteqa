import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
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
class VariantScreen extends StatefulWidget {
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
  State<VariantScreen> createState() => _VariantScreenState();
}

class _VariantScreenState extends State<VariantScreen> {
  late final FormStateStore _formStateStore;
  late final Map<String, dynamic> _dataContext;
  EngineActionDispatcher? _dispatcher;

  @override
  void initState() {
    super.initState();
    _formStateStore = FormStateStore();
    _dataContext = {FormStateStore.contextKey: _formStateStore};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dispatcher ??= EngineActionDispatcher(context: context);
    _dataContext[EngineActionDispatcher.contextKey] = _dispatcher;
  }

  @override
  void dispose() {
    _formStateStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('${widget.variantId}:${widget.pageRoute ?? ""}'),
      create: (context) => VariantCubit(
        widget.variantRepository,
        widget.variantId,
        pageRoute: widget.pageRoute,
      ),
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
                dataContext: _dataContext,
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
