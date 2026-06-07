import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/features/commerce/cart/data/repos/cart_repo.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_state.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart_line.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._repo) : super(const CartInitial());

  final CartRepo _repo;

  Map<String, int> _variantPriceIndex = const {};

  Cart? get _currentCart {
    final state = this.state;
    if (state is CartLoaded) return state.cart;
    if (state is CartActionSuccess) return state.cart;
    if (state is CartFailureState) return state.cart;
    return null;
  }

  void setVariantPriceIndex(Map<String, int> prices) {
    _variantPriceIndex = Map<String, int>.from(prices);
  }

  Future<void> loadCart() async {
    emit(const CartLoading());
    final result = await _repo.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(CartFailureState(failure.errMessage)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> addItem({
    required String variantId,
    required String productTitle,
    int quantity = 1,
    String? variantTitle,
    int? unitPrice,
    String? thumbnailUrl,
  }) async {
    final trimmedVariantId = variantId.trim();
    if (trimmedVariantId.isEmpty) {
      emit(
        CartFailureState(
          'يرجى اختيار الخيار قبل الإضافة إلى السلة',
          cart: _currentCart,
        ),
      );
      return;
    }

    final title = productTitle.trim();
    if (title.isEmpty) {
      emit(
        CartFailureState(
          'تعذر إضافة المنتج — العنوان غير متوفر',
          cart: _currentCart,
        ),
      );
      return;
    }

    if (quantity < 1) {
      emit(
        CartFailureState(
          'الكمية يجب أن تكون 1 على الأقل',
          cart: _currentCart,
        ),
      );
      return;
    }

    final resolvedPrice = unitPrice ??
        _variantPriceIndex[trimmedVariantId] ??
        0;
    if (resolvedPrice <= 0) {
      emit(
        CartFailureState(
          'تعذر إضافة المنتج — السعر غير متوفر',
          cart: _currentCart,
        ),
      );
      return;
    }

    final base = _currentCart ?? const Cart();
    final existingIndex = base.items.indexWhere(
      (line) => line.variantId == trimmedVariantId,
    );

    final List<CartLine> nextItems;
    if (existingIndex == -1) {
      nextItems = [
        ...base.items,
        CartLine(
          variantId: trimmedVariantId,
          quantity: quantity,
          productTitle: title,
          variantTitle: variantTitle?.trim().isEmpty == true
              ? null
              : variantTitle?.trim(),
          unitPrice: resolvedPrice,
          thumbnailUrl: thumbnailUrl?.trim().isEmpty == true
              ? null
              : thumbnailUrl?.trim(),
        ),
      ];
    } else {
      nextItems = List<CartLine>.from(base.items);
      final existing = nextItems[existingIndex];
      nextItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
        productTitle: title,
        variantTitle: variantTitle ?? existing.variantTitle,
        unitPrice: resolvedPrice,
        thumbnailUrl: thumbnailUrl ?? existing.thumbnailUrl,
      );
    }

    await _persistCart(Cart(items: nextItems), successMessage: 'تمت الإضافة إلى السلة');
  }

  Future<void> updateQuantity({
    required String variantId,
    int? quantity,
    int? delta,
  }) async {
    final id = variantId.trim();
    if (id.isEmpty) return;

    final base = _currentCart ?? const Cart();
    final index = base.items.indexWhere((line) => line.variantId == id);
    if (index == -1) return;

    final current = base.items[index];
    int nextQty;
    if (delta != null) {
      nextQty = current.quantity + delta;
    } else if (quantity != null) {
      nextQty = quantity;
    } else {
      return;
    }

    final nextItems = List<CartLine>.from(base.items);
    if (nextQty <= 0) {
      nextItems.removeAt(index);
    } else {
      nextItems[index] = current.copyWith(quantity: nextQty);
    }

    await _persistCart(Cart(items: nextItems));
  }

  Future<void> removeItem({required String variantId}) async {
    final id = variantId.trim();
    if (id.isEmpty) return;

    final base = _currentCart ?? const Cart();
    final nextItems =
        base.items.where((line) => line.variantId != id).toList();
    await _persistCart(Cart(items: nextItems));
  }

  Future<void> clear() async {
    final result = await _repo.clear();
    if (isClosed) return;
    result.fold(
      (failure) => emit(CartFailureState(failure.errMessage, cart: _currentCart)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> assertNotEmpty() async {
    final cart = _currentCart ?? const Cart();
    if (cart.isEmpty) {
      emit(const CartFailureState('السلة فارغة', cart: Cart()));
      return;
    }
    emit(CartLoaded(cart));
  }

  Future<void> _persistCart(
    Cart cart, {
    String? successMessage,
  }) async {
    final result = await _repo.save(cart);
    if (isClosed) return;
    result.fold(
      (failure) => emit(CartFailureState(failure.errMessage, cart: _currentCart)),
      (saved) {
        if (successMessage != null && successMessage.isNotEmpty) {
          emit(CartActionSuccess(saved, message: successMessage));
        } else {
          emit(CartLoaded(saved));
        }
      },
    );
  }
}
