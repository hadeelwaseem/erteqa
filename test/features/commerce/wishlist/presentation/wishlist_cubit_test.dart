import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/repos/wishlist_repo.dart';
import 'package:sooq_merchant/features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_cubit.dart';
import 'package:sooq_merchant/features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_state.dart';

class _MemoryWishlistRepo implements WishlistRepo {
  Wishlist _wishlist = const Wishlist();

  @override
  Future<Either<Failure, Wishlist>> clear() async {
    _wishlist = const Wishlist();
    return Right(_wishlist);
  }

  @override
  Future<Either<Failure, Wishlist>> load() async => Right(_wishlist);

  @override
  Future<Either<Failure, Wishlist>> save(Wishlist wishlist) async {
    _wishlist = wishlist;
    return Right(wishlist);
  }
}

void main() {
  late _MemoryWishlistRepo repo;
  late WishlistCubit cubit;

  setUp(() {
    repo = _MemoryWishlistRepo();
    cubit = WishlistCubit(repo);
  });

  tearDown(() => cubit.close());

  test('toggle adds then removes product', () async {
    await cubit.toggle(
      productId: 'p1',
      productTitle: 'منتج أ',
      displayPrice: '10 SYP',
    );

    expect(cubit.state, isA<WishlistActionSuccess>());
    expect(cubit.isFavorite('p1'), isTrue);

    await cubit.toggle(
      productId: 'p1',
      productTitle: 'منتج أ',
    );

    expect(cubit.isFavorite('p1'), isFalse);
    final wishlist = switch (cubit.state) {
      WishlistLoaded(:final wishlist) => wishlist,
      WishlistActionSuccess(:final wishlist) => wishlist,
      _ => null,
    };
    expect(wishlist?.items, isEmpty);
  });

  test('toggle fails when productId is empty', () async {
    await cubit.toggle(
      productId: '  ',
      productTitle: 'منتج',
    );

    expect(cubit.state, isA<WishlistFailureState>());
  });
}
