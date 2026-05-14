import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/engine/requests/request_mapper.dart';
import 'package:sooq_merchant/engine/tree/tree_engine.dart';
import 'package:sooq_merchant/features/product/presentation/manager/product_cubit/product_cubit.dart';
import 'package:sooq_merchant/features/variantscreen/data/repos/variant_repository.dart';
import 'package:sooq_merchant/features/variantscreen/presentation/manager/variant_cubit/variant_cubit.dart';

/// Dynamic screen host widget.
class VariantScreen extends StatefulWidget {
  const VariantScreen({
    super.key,
    required this.variantId,
    required this.variantRepository,
    this.pageRoute,
  });

  final String variantId;
  final VariantRepository variantRepository;
  final String? pageRoute;

  @override
  State<VariantScreen> createState() => _VariantScreenState();
}

class _VariantScreenState extends State<VariantScreen> {
  late final FormStateStore _formStateStore;
  late final Map<String, dynamic> _dataContext;
  final Map<String, dynamic> _requestResults = <String, dynamic>{};
  final Set<String> _loadingMoreRequestKeys = <String>{};
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
    _dispatcher ??= EngineActionDispatcher(
      context: context,
      formState: _formStateStore,
    );
    _dataContext[EngineActionDispatcher.contextKey] = _dispatcher;
  }

  @override
  void dispose() {
    _formStateStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VariantCubit>(
      key: ValueKey('${widget.variantId}:${widget.pageRoute ?? ''}'),
      create: (_) => VariantCubit(
        widget.variantRepository,
        widget.variantId,
        pageRoute: widget.pageRoute,
      ),
      child: BlocBuilder<VariantCubit, VariantState>(
        builder: (context, state) {
          return switch (state) {
            VariantInitial() || VariantLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            VariantSuccess(:final config) => _buildSuccessView(config),
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

  Widget _buildSuccessView(dynamic config) {
    final mappedRequests = EngineRequestMapper.collectRequests(config);
    final renderContext = _buildRenderContext();

    if (mappedRequests.isEmpty) {
      return ScreenRenderer.withPrimitives().render(
        config,
        context: context,
        dataContext: renderContext,
      );
    }

    return BlocProvider<ProductCubit>(
      create: (_) => getIt<ProductCubit>(),
      child: _ProductRequestHost(
        config: config,
        renderContext: renderContext,
        onProductSuccess: _handleProductSuccess,
        onProductFailure: _handleProductFailure,
      ),
    );
  }

  void _handleProductSuccess(
    String requestKey,
    dynamic productListResponse,
    bool isLoadMore,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      final nextData = productListResponse.data
          .map((item) => item.toJson())
          .toList();
      final existing = _requestResults[requestKey];
      final existingData = existing is Map<String, dynamic>
          ? (existing['data'] as List<dynamic>? ?? const <dynamic>[])
                .cast<dynamic>()
          : const <dynamic>[];

      _requestResults[requestKey] =
          isLoadMore && existing is Map<String, dynamic>
          ? {
              ...existing,
              'success': productListResponse.success,
              'message': productListResponse.message,
              'data': [...existingData, ...nextData],
              'meta': productListResponse.meta.toJson(),
              'timestamp': productListResponse.timestamp,
            }
          : {
              'success': productListResponse.success,
              'message': productListResponse.message,
              'data': nextData,
              'meta': productListResponse.meta.toJson(),
              'timestamp': productListResponse.timestamp,
            };
      _loadingMoreRequestKeys.remove(requestKey);
    });
  }

  void _handleProductFailure(
    String requestKey,
    String message,
    bool isLoadMore,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingMoreRequestKeys.remove(requestKey);
      if (isLoadMore && _requestResults[requestKey] is Map<String, dynamic>) {
        _requestResults[requestKey] = {
          ..._requestResults[requestKey] as Map<String, dynamic>,
          'loadMoreError': message,
        };
      } else {
        _requestResults[requestKey] = {
          'success': false,
          'message': message,
          'data': const <Map<String, dynamic>>[],
          'meta': const {},
          'timestamp': 0,
        };
      }
    });
  }

  Map<String, dynamic> _buildRenderContext() {
    final merged = <String, dynamic>{..._dataContext};
    if (_requestResults.isNotEmpty) {
      merged['requests'] = _requestResults;
      merged['loadingMoreRequests'] = {
        for (final key in _loadingMoreRequestKeys) key: true,
      };

      final productResult = _requestResults['product-list'];
      if (productResult is Map<String, dynamic>) {
        merged['products'] = productResult['data'] ?? const <dynamic>[];
      }
    }
    return merged;
  }
}

class _ProductRequestHost extends StatefulWidget {
  const _ProductRequestHost({
    required this.config,
    required this.renderContext,
    required this.onProductSuccess,
    required this.onProductFailure,
  });

  final dynamic config;
  final Map<String, dynamic> renderContext;
  final void Function(
    String requestKey,
    dynamic productListResponse,
    bool isLoadMore,
  )
  onProductSuccess;
  final void Function(String requestKey, String message, bool isLoadMore)
  onProductFailure;

  @override
  State<_ProductRequestHost> createState() => _ProductRequestHostState();
}

class _ProductRequestHostState extends State<_ProductRequestHost> {
  final Set<String> _dispatchedRequestKeys = <String>{};
  final Set<String> _loadingRequestKeys = <String>{};
  final Set<String> _loadingMoreRequestKeys = <String>{};
  bool _dispatchScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleDispatch();
  }

  @override
  void didUpdateWidget(covariant _ProductRequestHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _dispatchedRequestKeys.clear();
      _dispatchScheduled = false;
      _scheduleDispatch();
    }
  }

  void _scheduleDispatch() {
    if (_dispatchScheduled) {
      return;
    }
    _dispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _dispatchRequests();
    });
  }

  Future<void> _dispatchRequests() async {
    final mapped = EngineRequestMapper.collectRequests(widget.config);
    final pending = mapped
        .where((request) => !_dispatchedRequestKeys.contains(request.key))
        .toList(growable: false);

    if (pending.isEmpty) {
      return;
    }

    _dispatchedRequestKeys.addAll(pending.map((request) => request.key));
    await EngineRequestMapper.dispatchRequests(
      productCubit: context.read<ProductCubit>(),
      tenantId: null,
      requests: pending,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductCubit, ProductState>(
          listener: (context, state) {
            if (state is ProductLoading) {
              setState(() {
                if (state.isLoadMore) {
                  _loadingMoreRequestKeys.add(state.requestKey);
                  widget.renderContext['loadingMoreRequests'] = {
                    for (final key in _loadingMoreRequestKeys) key: true,
                  };
                } else {
                  _loadingRequestKeys.add(state.requestKey);
                }
              });
            } else if (state is ProductSuccess) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _loadingMoreRequestKeys.remove(state.requestKey);
                widget.renderContext['loadingMoreRequests'] = {
                  for (final key in _loadingMoreRequestKeys) key: true,
                };
              });
              widget.onProductSuccess(
                state.requestKey,
                state.productListResponse,
                state.isLoadMore,
              );
            } else if (state is ProductFailure) {
              setState(() {
                _loadingRequestKeys.remove(state.requestKey);
                _loadingMoreRequestKeys.remove(state.requestKey);
                widget.renderContext['loadingMoreRequests'] = {
                  for (final key in _loadingMoreRequestKeys) key: true,
                };
              });
              widget.onProductFailure(
                state.requestKey,
                state.errMessage,
                state.isLoadMore,
              );
            }
          },
        ),
      ],
      child: Stack(
        children: [
          ScreenRenderer.withPrimitives().render(
            widget.config,
            context: context,
            dataContext: widget.renderContext,
          ),
          if (_loadingRequestKeys.isNotEmpty)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x14FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
