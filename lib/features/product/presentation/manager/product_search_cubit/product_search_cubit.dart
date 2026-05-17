import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/product_search_result.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

part 'product_search_state.dart';

/// Orchestrates product search with 300ms debounce and request cancellation.
class ProductSearchCubit extends Cubit<ProductSearchState> {
  ProductSearchCubit(this._productRepo) : super(ProductSearchInitial());

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  final ProductRepo _productRepo;
  String _tenantId = '';
  CancelToken? _activeToken;
  Timer? _debounceTimer;

  void setTenantId(String tenantId) {
    if (tenantId.isNotEmpty) {
      _tenantId = tenantId;
    }
  }

  String? get _optionalTenantId => _tenantId.isEmpty ? null : _tenantId;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _activeToken?.cancel();
    return super.close();
  }

  void search({
    String? q,
    String? categoryId,
    String? tagId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    int page = 0,
    int size = 20,
    String? sort,
    String requestKey = 'product-search',
    bool isLoadMore = false,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(
        _executeSearch(
          q: q,
          categoryId: categoryId,
          tagId: tagId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          inStockOnly: inStockOnly,
          page: page,
          size: size,
          sort: sort,
          requestKey: requestKey,
          isLoadMore: isLoadMore,
        ),
      );
    });
  }

  Future<void> _executeSearch({
    String? q,
    String? categoryId,
    String? tagId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    required int page,
    required int size,
    String? sort,
    required String requestKey,
    required bool isLoadMore,
  }) async {
    _activeToken?.cancel();
    _activeToken = CancelToken();

    final previousPage = _previousPageForLoadMore(requestKey, isLoadMore);
    final token = _activeToken;

    if (isClosed) {
      return;
    }
    emit(ProductSearchLoading(requestKey: requestKey, isLoadMore: isLoadMore));

    final result = await _productRepo.searchProducts(
      q: q,
      categoryId: categoryId,
      tagId: tagId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStockOnly: inStockOnly,
      page: page,
      size: size,
      sort: sort,
      tenantId: _optionalTenantId,
      cancelToken: token,
    );

    if (isClosed || token != _activeToken) {
      return;
    }

    result.fold(
      (failure) {
        if (failure is RequestCancelledFailure) {
          return;
        }
        if (isClosed) {
          return;
        }
        emit(
          ProductSearchFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
            isLoadMore: isLoadMore,
          ),
        );
      },
      (searchResult) {
        if (isClosed) {
          return;
        }
        emit(
          ProductSearchSuccess(
            requestKey: requestKey,
            searchResult: _mergeLoadMore(
              previousPage: previousPage,
              nextPage: searchResult,
            ),
            isLoadMore: isLoadMore,
          ),
        );
      },
    );
  }

  Future<void> loadNextPage(
    ProductSearchResult current, {
    String requestKey = 'product-search',
    String? q,
    String? categoryId,
    String? tagId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    String? sort,
  }) async {
    if (!current.meta.hasNext) {
      return;
    }

    await _executeSearch(
      q: q,
      categoryId: categoryId,
      tagId: tagId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStockOnly: inStockOnly,
      page: current.meta.page + 1,
      size: current.meta.size,
      sort: sort,
      requestKey: requestKey,
      isLoadMore: true,
    );
  }

  ProductSearchResult? _previousPageForLoadMore(
    String requestKey,
    bool isLoadMore,
  ) {
    if (!isLoadMore) {
      return null;
    }

    final currentState = state;
    if (currentState is! ProductSearchSuccess ||
        currentState.requestKey != requestKey) {
      return null;
    }

    return currentState.searchResult;
  }

  ProductSearchResult _mergeLoadMore({
    required ProductSearchResult? previousPage,
    required ProductSearchResult nextPage,
  }) {
    if (previousPage == null) {
      return nextPage;
    }

    return nextPage.copyWith(
      products: [...previousPage.products, ...nextPage.products],
    );
  }
}
