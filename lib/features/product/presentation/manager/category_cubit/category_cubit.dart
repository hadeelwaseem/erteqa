import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/product/data/models/category.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._productRepo) : super(CategoryInitial());

  final ProductRepo _productRepo;
  String _tenantId = '';

  void setTenantId(String tenantId) {
    if (tenantId.isNotEmpty) {
      _tenantId = tenantId;
    }
  }

  String? get _optionalTenantId => _tenantId.isEmpty ? null : _tenantId;

  Future<void> loadTree({String requestKey = 'category-tree'}) async {
    if (isClosed) {
      return;
    }
    emit(CategoryLoading(requestKey: requestKey));

    final result = await _productRepo.getCategories(
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
          CategoryFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
          ),
        );
      },
      (categories) {
        if (isClosed) {
          return;
        }
        emit(
          CategoryTreeSuccess(
            requestKey: requestKey,
            categories: categories,
          ),
        );
      },
    );
  }

  Future<void> loadCategory(
    String slug, {
    String requestKey = 'category-detail',
  }) async {
    if (isClosed) {
      return;
    }
    emit(CategoryLoading(requestKey: requestKey));

    final result = await _productRepo.getCategory(
      slug: slug,
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
          CategoryFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
          ),
        );
      },
      (category) {
        if (isClosed) {
          return;
        }
        emit(
          CategorySuccess(
            requestKey: requestKey,
            category: category,
          ),
        );
      },
    );
  }
}
