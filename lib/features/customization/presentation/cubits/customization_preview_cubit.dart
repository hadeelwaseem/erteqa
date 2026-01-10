import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/core/enums/card_style.dart';
import 'package:sooq_merchant/features/customization/data/models/store_colors_model.dart';
import 'package:sooq_merchant/features/customization/data/models/store_layout_model.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_state.dart';

class CustomizationPreviewCubit extends Cubit<CustomizationPreviewState> {
  CustomizationPreviewCubit({
    required StoreColorsModel colors,
    required StoreLayoutModel layout,
  }) : super(CustomizationPreviewState(colors: colors, layout: layout));

  void updatePrimary(Color color) =>
      emit(state.copyWith(colors: state.colors.copyWith(primary: color)));
  void updateSecondary(Color color) =>
      emit(state.copyWith(colors: state.colors.copyWith(secondary: color)));
  void updateBackground(Color color) =>
      emit(state.copyWith(colors: state.colors.copyWith(background: color)));
  void updateButton(Color color) =>
      emit(state.copyWith(colors: state.colors.copyWith(button: color)));
  void updateSuccess(Color color) =>
      emit(state.copyWith(colors: state.colors.copyWith(success: color)));
  void updateText(Color color) =>
      emit(state.copyWith(colors: state.colors.copyWith(text: color)));

  void updateCardStyle(CardStyleType style) =>
      emit(state.copyWith(layout: state.layout.copyWith(cardStyle: style)));
}
