import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/cart/data/datasources/cart_local_storage.dart';
import 'package:sooq_merchant/features/commerce/cart/data/repos/cart_repo.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';

class CartRepoImpl implements CartRepo {
  CartRepoImpl(this._storage);

  final CartLocalStorage _storage;

  @override
  Future<Either<Failure, Cart>> load() async {
    try {
      return Right(await _storage.load());
    } catch (e) {
      return Left(ServerFailure('تعذر تحميل السلة'));
    }
  }

  @override
  Future<Either<Failure, Cart>> save(Cart cart) async {
    try {
      await _storage.save(cart);
      return Right(cart);
    } catch (e) {
      return Left(ServerFailure('تعذر حفظ السلة'));
    }
  }

  @override
  Future<Either<Failure, Cart>> clear() async {
    try {
      await _storage.clear();
      return const Right(Cart());
    } catch (e) {
      return Left(ServerFailure('تعذر مسح السلة'));
    }
  }
}
