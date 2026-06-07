import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:sooq_merchant/features/commerce/checkout/data/models/checkout_draft.dart';
import 'package:sooq_merchant/features/commerce/data/models/customer_order.dart';

/// Persists checkout wizard draft across route pushes.
class CheckoutSessionStore {
  CheckoutSessionStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const String storageKey = 'sooq.mobile.checkout.v1';

  SharedPreferences? _prefs;
  final _uuid = const Uuid();

  Future<SharedPreferences> _preferences() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<CheckoutDraft> loadDraft() async {
    final prefs = await _preferences();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const CheckoutDraft();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const CheckoutDraft();
      }
      return CheckoutDraft.fromJson(decoded);
    } catch (_) {
      return const CheckoutDraft();
    }
  }

  Future<void> saveDraft(CheckoutDraft draft) async {
    final prefs = await _preferences();
    await prefs.setString(storageKey, jsonEncode(draft.toJson()));
  }

  /// Generates a UUIDv4 checkout token once per checkout attempt.
  Future<String> ensureCheckoutToken(CheckoutDraft draft) async {
    final existing = draft.checkoutToken?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final token = _uuid.v4();
    final next = draft.copyWith(checkoutToken: token);
    await saveDraft(next);
    return token;
  }

  /// Clears wizard fields after a successful order; keeps [lastOrder].
  Future<CheckoutDraft> clearAfterSuccess({
    required CustomerOrder lastOrder,
  }) async {
    final next = CheckoutDraft(lastOrder: lastOrder);
    await saveDraft(next);
    return next;
  }

  Future<void> startNewCheckout() async {
    final prefs = await _preferences();
    await prefs.remove(storageKey);
  }
}
