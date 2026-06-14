import 'bootstrap_config.dart';

/// Loads the full runtime UI config JSON (theme, navigation, pages).
abstract class AppConfigSource {
  Future<Map<String, dynamic>> loadFullConfig(BootstrapConfig bootstrap);
}
