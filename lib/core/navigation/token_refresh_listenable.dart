import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';

/// Notifies [GoRouter] when [TokenCubit] session state changes.
class TokenRefreshListenable extends ChangeNotifier {
  TokenRefreshListenable(TokenCubit tokenCubit) {
    _subscription = tokenCubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<String?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
