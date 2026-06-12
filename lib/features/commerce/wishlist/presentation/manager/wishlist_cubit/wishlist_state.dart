import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist.dart';

sealed class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

final class WishlistInitial extends WishlistState {
  const WishlistInitial();
}

final class WishlistLoading extends WishlistState {
  const WishlistLoading();
}

final class WishlistLoaded extends WishlistState {
  const WishlistLoaded(this.wishlist);

  final Wishlist wishlist;

  @override
  List<Object?> get props => [wishlist];
}

final class WishlistFailureState extends WishlistState {
  const WishlistFailureState(this.message, {this.wishlist});

  final String message;
  final Wishlist? wishlist;

  @override
  List<Object?> get props => [message, wishlist];
}

final class WishlistActionSuccess extends WishlistState {
  const WishlistActionSuccess(this.wishlist, {this.message});

  final Wishlist wishlist;
  final String? message;

  @override
  List<Object?> get props => [wishlist, message];
}
