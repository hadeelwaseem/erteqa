import 'package:sooq_merchant/config/screen_config.dart';

class AppConfig {
  final String appName;
  final String bundleId;
  final List<ScreenConfig> screens;

  const AppConfig({
    required this.appName,
    required this.bundleId,
    required this.screens,
  });
}
