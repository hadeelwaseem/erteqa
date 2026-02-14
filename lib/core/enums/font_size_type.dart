enum FontSizeType { small, medium, large }

extension FontSizeTypeX on FontSizeType {
  double get value {
    switch (this) {
      case FontSizeType.small:
        return 14;
      case FontSizeType.medium:
        return 16;
      case FontSizeType.large:
        return 18;
    }
  }
}
