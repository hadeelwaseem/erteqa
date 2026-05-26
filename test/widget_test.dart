// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';

import 'package:sooq_merchant/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Provide the required non-null dependencies for SOOQApp.
    // You may need to import the necessary packages and create minimal test doubles or mocks if needed.
    // Example with simple test doubles (replace with actual implementations if available):

    // Import actual classes if not already imported:
    // import 'package:go_router/go_router.dart';
    // import 'package:sooq_merchant/core/utils/service_locator.dart';
    // import 'package:sooq_merchant/features/auth/presentation/cubit/token_cubit.dart';
    // import 'package:sooq_merchant/features/shared_preferences/presentation/cubit/shared_preferences_cubit.dart';

    // Set up minimal non-null instances for router and cubits.
    final router = GoRouter(routes: []); // Empty routes for testing
    final tokenCubit = TokenCubit(
      getIt<AuthTokenStorage>(),
    ); // Assumes a default constructor exists
    final sharedPreferencesCubit =
        SharedPreferencesCubit(); // Assumes a default constructor exists

    await tester.pumpWidget(
      SOOQApp(
        router: router,
        tokenCubit: tokenCubit,
        sharedPreferencesCubit: sharedPreferencesCubit,
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
