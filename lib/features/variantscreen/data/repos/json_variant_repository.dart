import '../../../../config/screen_config.dart';
import 'variant_config_parser.dart';
import 'variant_repository.dart';

/// Loads screen configs from session-resolved JSON (cache, remote, or asset).
///
/// JSON lives in RAM for the current app session only — not disk cache.
class JsonVariantRepository implements VariantRepository {
  final Map<String, dynamic> _configJson;

  JsonVariantRepository(this._configJson);

  @override
  Future<ScreenConfig> loadVariant(
    String variantId, {
    String? pageRoute,
  }) {
    return Future.value(
      VariantConfigParser.parseFromRoot(
        _configJson,
        variantId,
        pageRoute: pageRoute,
      ),
    );
  }
}
