import 'package:sooq_merchant/config/models/mobile_theme_config.dart';
import 'package:sooq_merchant/engine/theme/engine_theme.dart';

Map<String, dynamic> rendererDataContext() {
  return {
    EngineTheme.contextKey: EngineTheme.fromConfig(MobileThemeConfig.defaults()),
  };
}
