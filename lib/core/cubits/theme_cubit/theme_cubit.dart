import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

//TODO: check if we still need it after config the themeing
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light); // تعيين الوضع الافتراضي

  void toggleTheme() {
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.light);
    }
  }
}
