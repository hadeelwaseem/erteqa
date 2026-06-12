import 'package:dartz/dartz.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist.dart';

abstract class WishlistRepo {
  Future<Either<Failure, Wishlist>> load();

  Future<Either<Failure, Wishlist>> save(Wishlist wishlist);

  Future<Either<Failure, Wishlist>> clear();
}
