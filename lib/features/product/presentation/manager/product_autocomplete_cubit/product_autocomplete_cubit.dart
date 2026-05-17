import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/product_autocomplete_result.dart';
import 'package:sooq_merchant/features/product/data/repos/product_repo.dart';

part 'product_autocomplete_state.dart';

/// Orchestrates autocomplete with 300ms debounce and request cancellation.
class ProductAutocompleteCubit extends Cubit<ProductAutocompleteState> {
  ProductAutocompleteCubit(this._productRepo) : super(ProductAutocompleteInitial());

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

  void fetchSuggestions(
    String q, {
    String requestKey = 'product-autocomplete',
  }) {
    _debounceTimer?.cancel();

    if (q.trim().length < 3) {
      if (isClosed) {
        return;
      }
      emit(ProductAutocompleteInitial());
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      unawaited(_executeFetch(q: q.trim(), requestKey: requestKey));
    });
  }

  Future<void> _executeFetch({
    required String q,
    required String requestKey,
  }) async {
    _activeToken?.cancel();
    _activeToken = CancelToken();
    final token = _activeToken;

    if (isClosed) {
      return;
    }
    emit(ProductAutocompleteLoading(requestKey: requestKey));

    final result = await _productRepo.autocomplete(
      q: q,
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
          ProductAutocompleteFailure(
            requestKey: requestKey,
            errMessage: failure.errMessage,
          ),
        );
      },
      (autocompleteResult) {
        if (isClosed) {
          return;
        }
        emit(
          ProductAutocompleteSuccess(
            requestKey: requestKey,
            autocompleteResult: autocompleteResult,
          ),
        );
      },
    );
  }
}
