import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/errors/failures.dart';
import 'package:sooq_merchant/core/network/auth_token_storage.dart';
import 'package:sooq_merchant/core/feedback/app_messenger.dart';
import 'package:sooq_merchant/engine/actions/action_dispatcher.dart';
import 'package:sooq_merchant/engine/form/form_state_store.dart';
import 'package:sooq_merchant/features/auth/data/models/auth_token_response.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_request.dart';
import 'package:sooq_merchant/features/auth/data/models/customer_otp_verify_request.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';

class _FakeAuthRepo implements AuthRepo {
  CustomerOtpRequest? lastOtpRequest;

  @override
  Future<Either<Failure, String>> requestOtp({required CustomerOtpRequest request}) async {
    lastOtpRequest = request;
    return const Right('OTP sent via WhatsApp');
  }

  @override
  Future<Either<Failure, AuthTokenResponse>> verifyOtp({
    required CustomerOtpVerifyRequest request,
  }) async {
    throw UnimplementedError();
  }
}

class _MemoryTokenStorage implements AuthTokenStorage {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _tenantId;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _tenantId = null;
  }

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<DateTime?> readExpiresAt() async => _expiresAt;

  @override
  Future<String?> readTenantId() async => _tenantId;

  @override
  Future<AuthTokenBundle> readTokenBundle() async => AuthTokenBundle(
        accessToken: _accessToken,
        refreshToken: _refreshToken,
        expiresAt: _expiresAt,
        tenantId: _tenantId,
      );

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = expiresAt;
    _tenantId = tenantId;
  }
}

void main() {
  final locator = GetIt.instance;
  late _FakeAuthRepo fakeRepo;

  setUp(() {
    fakeRepo = _FakeAuthRepo();
    if (locator.isRegistered<AuthRepo>()) {
      locator.unregister<AuthRepo>();
    }
    if (locator.isRegistered<AuthCubit>()) {
      locator.unregister<AuthCubit>();
    }
    if (locator.isRegistered<TokenCubit>()) {
      locator.unregister<TokenCubit>();
    }
    locator.registerLazySingleton<AuthRepo>(() => fakeRepo);
    locator.registerLazySingleton<TokenCubit>(() => TokenCubit(_MemoryTokenStorage()));
    locator.registerLazySingleton<AuthCubit>(
      () => AuthCubit(locator<AuthRepo>(), locator<TokenCubit>()),
    );
  });

  tearDown(() {
    AppMessenger.dismiss();
    if (locator.isRegistered<AuthCubit>()) {
      locator.unregister<AuthCubit>();
    }
    if (locator.isRegistered<TokenCubit>()) {
      locator.unregister<TokenCubit>();
    }
    if (locator.isRegistered<AuthRepo>()) {
      locator.unregister<AuthRepo>();
    }
  });

  testWidgets('cubitCall dispatches requestOtp with form and app params', (tester) async {
    final formState = FormStateStore();
    formState.updateValue('phone', '+963911000111');
    formState.updateValue('fullName', 'Ali');

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(
              context: context,
              formState: formState,
              dataContext: {
                'app': {'tenantSlug': 'store-a'},
              },
            );
            return Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => dispatcher.dispatch({
                      'type': 'cubitCall',
                      'cubit': 'auth',
                      'method': 'requestOtp',
                      'params': {
                        'phone': {'source': 'form', 'field': 'phone'},
                        'fullName': {'source': 'form', 'field': 'fullName'},
                        'tenantSlug': {'source': 'app', 'field': 'tenantSlug'},
                      },
                    }),
                    child: const Text('Send'),
                  );
                },
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastOtpRequest?.phone, '+963911000111');
    expect(fakeRepo.lastOtpRequest?.fullName, 'Ali');
    expect(fakeRepo.lastOtpRequest?.tenantSlug, 'store-a');
    expect(locator<AuthCubit>().state, isA<AuthOtpRequested>());
  });

  testWidgets('requireValidForm failure shows validation messenger', (tester) async {
    final formState = FormStateStore();
    final formKey = formState.formKeyFor('login');

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(
              context: context,
              formState: formState,
            );
            return Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    ElevatedButton(
                      onPressed: () => dispatcher.dispatch({
                        'type': 'navigate',
                        'route': '/home',
                        'requireValidForm': true,
                        'formId': 'login',
                      }),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('يرجى تصحيح الحقول'), findsOneWidget);
    AppMessenger.dismiss();
  });

  testWidgets('cubitCall logout clears token and navigates to login', (tester) async {
    await locator<TokenCubit>().storeToken('seed-access-token');

    late GoRouter router;

    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) {
            final dispatcher = EngineActionDispatcher(context: context);
            return Scaffold(
              body: ElevatedButton(
                onPressed: () => dispatcher.dispatch({
                  'type': 'cubitCall',
                  'cubit': 'auth',
                  'method': 'logout',
                  'onSuccess': {
                    'type': 'navigate',
                    'route': '/auth/login',
                    'navigation_type': 'clear_stack',
                  },
                }),
                child: const Text('Logout'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(locator<TokenCubit>().state, isNull);
    expect(locator<AuthCubit>().state, isA<AuthInitial>());
    expect(router.state.uri.path, '/auth/login');
    expect(router.canPop(), isFalse);
    expect(find.text('Login'), findsOneWidget);
  });
}
