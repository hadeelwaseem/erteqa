import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// import 'package:hive/hive.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo_impl.dart';
// import 'package:lms_student/features/auth/data/models/user_model/user.dart';
// import 'package:lms_student/features/auth/data/repos/auth_repo_impl.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/create_user_cubit/create_user_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/index_address_year_cubit/index_address_year_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/resend_email_cubit/resend_email_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/verify_user_cubit/verify_user_cubit.dart';
// import 'package:sooq_merchant/features/auth/presentation/manager/grades_cubit/grades_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/views/onboarding_view.dart';

abstract class AppRouter {
  static const kOnBoardingView = '/onBoardingView';
  static const kHomeView = '/homeView';

  static GoRouter setupRouter(String? token) {
    return GoRouter(
      routes: [
        if (token == null)
          //navigate to Auth/onBoarding Screen (He is not signingIn)
          //The Bellow code is example os how we will continue
          GoRoute(
            path: '/',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                // BlocProvider(
                //   create: (context) =>
                //       IndexAddressYearCubit(getIt<AuthRepoImpl>())
                //         ..fetchAuthData(),
                // ),
                BlocProvider(
                  create: (context) => CreateUserCubit(getIt<AuthRepoImpl>()),
                ),
                BlocProvider(
                  create: (context) => ResendEmailCubit(getIt<AuthRepoImpl>()),
                ),
                BlocProvider(
                  create: (context) => VerifyUserCubit(getIt<AuthRepoImpl>()),
                ),
                BlocProvider(
                  create: (context) => AuthCubit(getIt<AuthRepoImpl>()),
                ),
                BlocProvider(
                  create: (context) => getIt<SharedPreferencesCubit>(),
                ),
              ],
              child: OnBoaringView(),
            ),
          ),

        //else: the user is SiginedIn and should be navigated to Home screen
        //The Bellow code is example os how we will continue

        // if (token != null)
        //   GoRoute(
        //     path: '/',
        //     builder: (context, state) {
        //       return MultiBlocProvider(
        //         providers: [
        //           // BlocProvider(
        //           //     create: (context) => SubjectsCubit(
        //           //         getIt<HomeRepoImpl>(), gradeId ?? state.extra as String)
        //           //       ..fetchSubjects(
        //           //           gradeId: gradeId ?? state.extra as String)),
        //           BlocProvider(
        //               create: (context) => AdCubit(getIt<HomeRepoImpl>())),
        //           BlocProvider(
        //               create: (context) => SubjectsCubit(
        //                     getIt<HomeRepoImpl>(),
        //                   )),
        //         ],
        //         child: const HomeView(
        //             // gradeId: gradeId ?? state.extra as String,
        //             ),
        //       );
        //     },
        //   ),
      ],
    );
  }
}
