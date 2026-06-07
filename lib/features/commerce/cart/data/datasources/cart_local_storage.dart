import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooq_merchant/features/commerce/data/models/cart.dart';

/// Persists cart JSON under a stable key (compatible line shape with web v1).
class CartLocalStorage {
  CartLocalStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const String storageKey = 'sooq.mobile.cart.v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Cart> load() async {
    final prefs = await _preferences();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const Cart();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const Cart();
      }
      return Cart.fromJson(decoded);
    } catch (_) {
      return const Cart();
    }
  }

  Future<void> save(Cart cart) async {
    final prefs = await _preferences();
    await prefs.setString(storageKey, jsonEncode(cart.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _preferences();
    await prefs.remove(storageKey);
  }
}
