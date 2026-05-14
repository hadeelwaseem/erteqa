import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepo _productRepo;
  String _tenantId = 'aefc4436-3fd2-44cd-9647-09b8bd32e02a';

  ProductCubit(this._productRepo) : super(ProductInitial());

  /// Set the tenant ID for subsequent requests
  /// Only overwrites if the provided ID is not empty
  void setTenantId(String tenantId) {
    if (tenantId.isNotEmpty) {
      _tenantId = tenantId;
    }
  }

  /// Fetch products with pagination support
  Future<void> getProducts({
    int page = 0,
    int size = 20,
    String requestKey = 'product-list',
    bool isLoadMore = false,
  }) async {
    emit(ProductLoading(requestKey: requestKey, isLoadMore: isLoadMore));

    final result = await _productRepo.getProducts(
      page: page,
      size: size,
      tenantId: _tenantId,
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
            productListResponse: productListResponse,
            isLoadMore: isLoadMore,
          ),
        );
      },
    );
  }

  /// Load next page of products
  Future<void> loadNextPage(
    ProductListResponse currentResponse, {
    String requestKey = 'product-list',
  }) async {
    if (currentResponse.meta.hasNext) {
      await getProducts(
        page: currentResponse.meta.page + 1,
        size: currentResponse.meta.size,
        requestKey: requestKey,
        isLoadMore: true,
      );
    }
  }

  /// Load previous page of products
  Future<void> loadPreviousPage(
    ProductListResponse currentResponse, {
    String requestKey = 'product-list',
  }) async {
    if (currentResponse.meta.hasPrev) {
      await getProducts(
        page: currentResponse.meta.page - 1,
        size: currentResponse.meta.size,
        requestKey: requestKey,
      );
    }
  }
}
