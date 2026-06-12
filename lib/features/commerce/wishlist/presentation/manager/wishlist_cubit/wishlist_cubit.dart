import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist_item.dart';
import 'package:sooq_merchant/features/commerce/wishlist/data/repos/wishlist_repo.dart';
import 'package:sooq_merchant/features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_state.dart';

class WishlistCubit extends Cubit<WishlistState> {
  WishlistCubit(this._repo) : super(const WishlistInitial());

  final WishlistRepo _repo;

  Wishlist? get _currentWishlist {
    final state = this.state;
    if (state is WishlistLoaded) return state.wishlist;
    if (state is WishlistActionSuccess) return state.wishlist;
    if (state is WishlistFailureState) return state.wishlist;
    return null;
  }

  Future<void> load() async {
    emit(const WishlistLoading());
    final result = await _repo.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(WishlistFailureState(failure.errMessage)),
      (wishlist) => emit(WishlistLoaded(wishlist)),
    );
  }

  bool isFavorite(String productId) {
    final base = _currentWishlist ?? const Wishlist();
    return base.containsProduct(productId);
  }

  Future<void> add({
    required String productId,
    required String productTitle,
    String? thumbnailUrl,
    String? displayPrice,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) {
      emit(
        WishlistFailureState(
          'تعذر الإضافة — معرف المنتج غير متوفر',
          wishlist: _currentWishlist,
        ),
      );
      return;
    }

    final title = productTitle.trim();
    if (title.isEmpty) {
      emit(
        WishlistFailureState(
          'تعذر الإضافة — العنوان غير متوفر',
          wishlist: _currentWishlist,
        ),
      );
      return;
    }

    final base = _currentWishlist ?? const Wishlist();
    if (base.containsProduct(id)) {
      emit(WishlistLoaded(base));
      return;
    }

    final nextItems = [
      ...base.items,
      WishlistItem(
        productId: id,
        productTitle: title,
        thumbnailUrl: thumbnailUrl?.trim().isEmpty == true
            ? null
            : thumbnailUrl?.trim(),
        displayPrice: displayPrice?.trim().isEmpty == true
            ? null
            : displayPrice?.trim(),
      ),
    ];

    await _persistWishlist(
      Wishlist(items: nextItems),
      successMessage: 'تمت الإضافة إلى المفضلة',
    );
  }

  Future<void> remove({required String productId}) async {
    final id = productId.trim();
    if (id.isEmpty) return;

    final base = _currentWishlist ?? const Wishlist();
    final nextItems =
        base.items.where((item) => item.productId != id).toList();

    await _persistWishlist(
      Wishlist(items: nextItems),
      successMessage: 'تمت الإزالة من المفضلة',
    );
  }

  Future<void> toggle({
    required String productId,
    required String productTitle,
    String? thumbnailUrl,
    String? displayPrice,
  }) async {
    final id = productId.trim();
    if (id.isEmpty) {
      emit(
        WishlistFailureState(
          'تعذر تحديث المفضلة — معرف المنتج غير متوفر',
          wishlist: _currentWishlist,
        ),
      );
      return;
    }

    if (isFavorite(id)) {
      await remove(productId: id);
    } else {
      await add(
        productId: id,
        productTitle: productTitle,
        thumbnailUrl: thumbnailUrl,
        displayPrice: displayPrice,
      );
    }
  }

  Future<void> clear() async {
    final result = await _repo.clear();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(WishlistFailureState(failure.errMessage, wishlist: _currentWishlist)),
      (wishlist) => emit(WishlistLoaded(wishlist)),
    );
  }

  Future<void> _persistWishlist(
    Wishlist wishlist, {
    String? successMessage,
  }) async {
    final result = await _repo.save(wishlist);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(WishlistFailureState(failure.errMessage, wishlist: _currentWishlist)),
      (saved) {
        if (successMessage != null && successMessage.isNotEmpty) {
          emit(WishlistActionSuccess(saved, message: successMessage));
        } else {
          emit(WishlistLoaded(saved));
        }
      },
    );
  }
}
