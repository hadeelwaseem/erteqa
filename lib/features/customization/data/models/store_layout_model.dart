import 'package:sooq_merchant/core/enums/card_style.dart';

class StoreLayoutModel {
  final CardStyleType cardStyle;

  const StoreLayoutModel({required this.cardStyle});

  StoreLayoutModel copyWith({required CardStyleType cardStyle}) {
    return StoreLayoutModel(cardStyle: cardStyle);
  }

  factory StoreLayoutModel.defaultLayout() {
    return const StoreLayoutModel(cardStyle: CardStyleType.rounded);
  }
}
