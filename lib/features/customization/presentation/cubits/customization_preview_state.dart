import 'package:sooq_merchant/features/customization/data/models/store_colors_model.dart';
import 'package:sooq_merchant/features/customization/data/models/store_layout_model.dart';

class CustomizationPreviewState {
  final StoreColorsModel colors;
  final StoreLayoutModel layout;

  CustomizationPreviewState({required this.colors, required this.layout});

  CustomizationPreviewState copyWith({
    StoreColorsModel? colors,
    StoreLayoutModel? layout,
  }) {
    return CustomizationPreviewState(
      colors: colors ?? this.colors,
      layout: layout ?? this.layout,
    );
  }
}
