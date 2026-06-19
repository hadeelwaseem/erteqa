import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sooq_merchant/config/mobile_app_config.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/cubits/token_cubit/token_cubit.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/core/utils/size_config.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';
import 'package:sooq_merchant/features/commerce/cart/presentation/manager/cart_cubit/cart_cubit.dart';
import 'package:sooq_merchant/features/commerce/checkout/presentation/manager/checkout_cubit/checkout_cubit.dart';
import 'package:sooq_merchant/features/commerce/order/presentation/manager/order_cubit/order_cubit.dart';
import 'package:sooq_merchant/features/commerce/wishlist/presentation/manager/wishlist_cubit/wishlist_cubit.dart';

class SOOQApp extends StatelessWidget {
  final GoRouter router;
  final TokenCubit tokenCubit;
  final SharedPreferencesCubit sharedPreferencesCubit;
  final MobileAppConfig? mobileAppConfig;

  const SOOQApp({
    super.key,
    required this.router,
    required this.tokenCubit,
    required this.sharedPreferencesCubit,
    this.mobileAppConfig,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tokenCubit),
        BlocProvider.value(value: sharedPreferencesCubit),
        BlocProvider.value(value: getIt<CartCubit>()),
        BlocProvider.value(value: getIt<WishlistCubit>()),
        BlocProvider.value(value: getIt<CheckoutCubit>()),
        BlocProvider.value(value: getIt<OrderCubit>()),
      ],
      child: Builder(
        builder: (context) {
          SizeConfig.init(context);
          return MaterialApp.router(
            theme: mobileAppConfig != null
                ? EngineTheme.toThemeData(mobileAppConfig!.theme)
                : ThemeData(useMaterial3: true),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: (context, child) {
              final isRtl = context.locale.languageCode == 'ar';
              return Directionality(
                textDirection: isRtl
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
