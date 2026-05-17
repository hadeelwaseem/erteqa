import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/product/data/models/product_detail.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

part 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this._productRepo) : super(ProductDetailInitial());

  final ProductRepo _productRepo;
  String _tenantId = '';

  void setTenantId(String tenantId) {
    if (tenantId.isNotEmpty) {
      _tenantId = tenantId;
    }
  }

  String? get _optionalTenantId => _tenantId.isEmpty ? null : _tenantId;

  Future<void> loadDetail(
    String slug, {
    String? include,
    String requestKey = 'product-detail',
  }) async {
    if (isClosed) {
      return;
    }
    emit(ProductDetailLoading(requestKey: requestKey));

    final result = await _productRepo.getProductDetail(
      slug: slug,
      include: include,
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
          ProductDetailFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
          ),
        );
      },
      (detail) {
        if (isClosed) {
          return;
        }
        emit(
          ProductDetailSuccess(
            requestKey: requestKey,
            detail: detail,
          ),
        );
      },
    );
  }
}
