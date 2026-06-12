import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/datasources/wishlist_local_storage.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/repos/wishlist_repo.dart';

class WishlistRepoImpl implements WishlistRepo {
  WishlistRepoImpl(this._storage);

  final WishlistLocalStorage _storage;

  @override
  Future<Either<Failure, Wishlist>> load() async {
    try {
      return Right(await _storage.load());
    } catch (e) {
      return Left(ServerFailure('تعذر تحميل المفضلة'));
    }
  }

  @override
  Future<Either<Failure, Wishlist>> save(Wishlist wishlist) async {
    try {
      await _storage.save(wishlist);
      return Right(wishlist);
    } catch (e) {
      return Left(ServerFailure('تعذر حفظ المفضلة'));
    }
  }

  @override
  Future<Either<Failure, Wishlist>> clear() async {
    try {
      await _storage.clear();
      return const Right(Wishlist());
    } catch (e) {
      return Left(ServerFailure('تعذر مسح المفضلة'));
    }
  }
}
