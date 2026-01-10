import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:sooq_merchant/features/customization/data/models/store_colors_model.dart';

class CustomizationCubit extends Cubit<StoreColorsModel> {
  CustomizationCubit()
    : super(
        StoreColorsModel(
          primary: const Color(0xFF273B56),
          secondary: const Color(0xFFE5E7EB),
          background: const Color(0xFFF5F6FA),
          button: const Color(0xFF1E2A3A),
          success: const Color(0xFF8DB9A0),
          text: Colors.black,
        ),
      );

  void updatePrimary(Color color) => emit(state.copyWith(primary: color));

  void updateButton(Color color) => emit(state.copyWith(button: color));

  void updateBackground(Color color) => emit(state.copyWith(background: color));

  void updateSecondary(Color color) => emit(state.copyWith(secondary: color));

  void updateSuccess(Color color) => emit(state.copyWith(success: color));

  void updateText(Color color) => emit(state.copyWith(text: color));

  void applyTheme(StoreColorsModel colors) {
    emit(colors);
  }
}
