import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartLoaded extends CartState {
  const CartLoaded(this.cart);

  final Cart cart;

  @override
  List<Object?> get props => [cart];
}

final class CartFailureState extends CartState {
  const CartFailureState(this.message, {this.cart});

  final String message;
  final Cart? cart;

  @override
  List<Object?> get props => [message, cart];
}

/// Emitted briefly after successful mutations (e.g. add to cart) for UI feedback.
final class CartActionSuccess extends CartState {
  const CartActionSuccess(this.cart, {this.message});

  final Cart cart;
  final String? message;

  @override
  List<Object?> get props => [cart, message];
}
