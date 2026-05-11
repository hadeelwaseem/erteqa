import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/product/data/models/product_list_response.dart';

abstract class ProductRepo {
  Future<Either<Failure, ProductListResponse>> getProducts({
    required int page,
    required int size,
    required String tenantId,
  });
}
