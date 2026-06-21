import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/navigation/auth_prompt_sheet.dart';
import 'package:sooq_merchant/core/navigation/auth_redirect.dart';

void main() {
  testWidgets('AuthPromptSheet shows title and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => AuthPromptSheet.show(context),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('AuthPromptSheet cancel dismisses without navigation', (tester) async {
    late GoRouter router;

    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => AuthPromptSheet.show(context),
                child: const Text('Open'),
              ),
            );
          },
        ),
        GoRoute(
          path: AuthRedirect.loginRoute,
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/start');
    expect(find.text('Login'), findsNothing);
  });

  testWidgets('AuthPromptSheet login navigates to auth login', (tester) async {
    late GoRouter router;

    router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => AuthPromptSheet.show(context),
                child: const Text('Open'),
              ),
            );
          },
        ),
        GoRoute(
          path: AuthRedirect.loginRoute,
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AuthRedirect.loginRoute);
    expect(find.text('Login'), findsOneWidget);
  });
}
