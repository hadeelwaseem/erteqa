// import 'package:lms_student/constants.dart';
// import 'package:lms_student/core/cubits/directory_cubit/directory_cubit.dart';
// import 'package:lms_student/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
// import 'package:lms_student/core/cubits/token_cubit/token_cubit.dart';
// import 'package:lms_student/core/utils/service_locator.dart';
// import 'package:lms_student/features/downloads/data/models/file_state/file_state.dart';
// import 'package:hive/hive.dart';

// void resetApp() async {
//   // final authorizeCubit = getIt<AuthorizeCubit>();
//   final directoryCubit = getIt<DirectoryCubit>();
//   final sharedPreferencesCubit = getIt<SharedPreferencesCubit>();
//   // final tempDirectoryCubit = getIt<TempDirectoryCubit>();

//   final tokenCubit = getIt<TokenCubit>();
//   // authorizeCubit.setup(false);
//   tokenCubit.deleteSavedToken();
//   directoryCubit.clearAllData();
//   // tempDirectoryCubit.clearAllData();
//   sharedPreferencesCubit.deleteAll();

//   clearBox<FileState>(kFileState);
// }

// void clearBox<T>(String boxName) async {
//   var box = Hive.box<T>(boxName);
//   await box.clear();
// }
