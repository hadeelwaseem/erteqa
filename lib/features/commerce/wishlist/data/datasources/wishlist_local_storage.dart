import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sooq_merchant/features/commerce/data/models/wishlist.dart';

/// Persists wishlist JSON under a stable key.
class WishlistLocalStorage {
  WishlistLocalStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const String storageKey = 'sooq.mobile.wishlist.v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Wishlist> load() async {
    final prefs = await _preferences();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const Wishlist();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const Wishlist();
      }
      return Wishlist.fromJson(decoded);
    } catch (_) {
      return const Wishlist();
    }
  }

  Future<void> save(Wishlist wishlist) async {
    final prefs = await _preferences();
    await prefs.setString(storageKey, jsonEncode(wishlist.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _preferences();
    await prefs.remove(storageKey);
  }
}
