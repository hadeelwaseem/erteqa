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
  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<String?> readTenantId() async => null;

  @override
  Future<AuthTokenBundle> readTokenBundle() async => const AuthTokenBundle();

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
    String? tenantId,
  }) async {}
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
}
