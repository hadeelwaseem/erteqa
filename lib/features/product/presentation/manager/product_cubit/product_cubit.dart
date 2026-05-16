import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

part 'product_state.dart';

class _ListRequestContext {
  const _ListRequestContext({
    this.categorySlug,
    this.sort,
    required this.size,
  });

  final String? categorySlug;
  final String? sort;
  final int size;
}

class ProductCubit extends Cubit<ProductState> {
  final ProductRepo _productRepo;
  String _tenantId = '';
  final Map<String, _ListRequestContext> _contextByKey = {};

  ProductCubit(this._productRepo) : super(ProductInitial());

  /// Set the tenant ID for subsequent requests
  /// Only overwrites if the provided ID is not empty
  void setTenantId(String tenantId) {
    if (tenantId.isNotEmpty) {
      _tenantId = tenantId;
    }
  }

  String? get _optionalTenantId => _tenantId.isEmpty ? null : _tenantId;

  /// Fetch products with pagination support
  Future<void> getProducts({
    int page = 0,
    int size = 20,
    String? sort,
    String requestKey = 'product-list',
    bool isLoadMore = false,
  }) async {
    _contextByKey[requestKey] = _ListRequestContext(sort: sort, size: size);
    final previousPage = _previousPageForLoadMore(requestKey, isLoadMore);

    if (isClosed) {
      return;
    }
    emit(ProductLoading(requestKey: requestKey, isLoadMore: isLoadMore));

    final result = await _productRepo.getProducts(
      page: page,
      size: size,
      sort: sort,
      tenantId: _optionalTenantId,
    );

    if (isClosed) {
      return;
    }

    result.fold(
      (failure) {
        if (isClosed) {
          return;
        }
        emit(
          ProductFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
            isLoadMore: isLoadMore,
          ),
        );
      },
      (productListResponse) {
        if (isClosed) {
          return;
        }
        emit(
          ProductSuccess(
            requestKey: requestKey,
            productListResponse: _mergeLoadMore(
              previousPage: previousPage,
              nextPage: productListResponse,
            ),
            isLoadMore: isLoadMore,
          ),
        );
      },
    );
  }

  /// Fetch paginated products for a category
  Future<void> getCategoryProducts({
    required String categorySlug,
    int page = 0,
    int size = 20,
    String? sort,
    String requestKey = 'product-list',
    bool isLoadMore = false,
  }) async {
    _contextByKey[requestKey] = _ListRequestContext(
      categorySlug: categorySlug,
      sort: sort,
      size: size,
    );
    final previousPage = _previousPageForLoadMore(requestKey, isLoadMore);

    if (isClosed) {
      return;
    }
    emit(ProductLoading(requestKey: requestKey, isLoadMore: isLoadMore));

    final result = await _productRepo.getCategoryProducts(
      categorySlug: categorySlug,
      page: page,
      size: size,
      sort: sort,
      tenantId: _optionalTenantId,
    );

    if (isClosed) {
      return;
    }

    result.fold(
      (failure) {
        if (isClosed) {
          return;
        }
        emit(
          ProductFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
            isLoadMore: isLoadMore,
          ),
        );
      },
      (productListResponse) {
        if (isClosed) {
          return;
        }
        emit(
          ProductSuccess(
            requestKey: requestKey,
            productListResponse: _mergeLoadMore(
              previousPage: previousPage,
              nextPage: productListResponse,
            ),
            isLoadMore: isLoadMore,
          ),
        );
      },
    );
  }

  ProductListResponse? _previousPageForLoadMore(
    String requestKey,
    bool isLoadMore,
  ) {
    if (!isLoadMore) {
      return null;
    }

    final currentState = state;
    if (currentState is! ProductSuccess || currentState.requestKey != requestKey) {
      return null;
    }

    return currentState.productListResponse;
  }

  ProductListResponse _mergeLoadMore({
    required ProductListResponse? previousPage,
    required ProductListResponse nextPage,
  }) {
    if (previousPage == null) {
      return nextPage;
    }

    return nextPage.copyWith(
      data: [...previousPage.data, ...nextPage.data],
    );
  }

  /// Load next page of products
  Future<void> loadNextPage(
    ProductListResponse currentResponse, {
    String requestKey = 'product-list',
  }) async {
    if (!currentResponse.meta.hasNext) {
      return;
    }

    final context = _contextByKey[requestKey];
    final nextPage = currentResponse.meta.page + 1;
    final size = context?.size ?? currentResponse.meta.size;

    if (context?.categorySlug != null) {
      await getCategoryProducts(
        categorySlug: context!.categorySlug!,
        page: nextPage,
        size: size,
        sort: context.sort,
        requestKey: requestKey,
        isLoadMore: true,
      );
      return;
    }

    await getProducts(
      page: nextPage,
      size: size,
      sort: context?.sort,
      requestKey: requestKey,
      isLoadMore: true,
    );
  }

  /// Load previous page of products
  Future<void> loadPreviousPage(
    ProductListResponse currentResponse, {
    String requestKey = 'product-list',
  }) async {
    if (!currentResponse.meta.hasPrev) {
      return;
    }

    final context = _contextByKey[requestKey];
    final previousPage = currentResponse.meta.page - 1;
    final size = context?.size ?? currentResponse.meta.size;

    if (context?.categorySlug != null) {
      await getCategoryProducts(
        categorySlug: context!.categorySlug!,
        page: previousPage,
        size: size,
        sort: context.sort,
        requestKey: requestKey,
      );
      return;
    }

    await getProducts(
      page: previousPage,
      size: size,
      sort: context?.sort,
      requestKey: requestKey,
    );
  }
}
