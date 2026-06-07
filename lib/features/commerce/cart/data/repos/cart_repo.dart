import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';

abstract class CartRepo {
  Future<Either<Failure, Cart>> load();

  Future<Either<Failure, Cart>> save(Cart cart);

  Future<Either<Failure, Cart>> clear();
}
