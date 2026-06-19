import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:sooq_merchant/app/launch_sooq_merchant_app.dart';
import 'package:sooq_merchant/core/bootstrap/config_bootstrap_error_app.dart';
import 'package:sooq_merchant/core/utils/app_logger.dart';
import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';
import 'package:sooq_merchant/engine/config_pipeline.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    return true;
  }());

  final pipelineResult = await ConfigPipeline.initialize();
  final mobileConfig = pipelineResult.mobileAppConfig;

  if (mobileConfig == null) {
    runApp(ConfigBootstrapErrorApp(pipelineResult: pipelineResult));
    return;
  }

  if (AuthMockConfig.enabled) {
    AppLogger.auth(
      'TEMPORARY: Auth mock enabled — see lib/dev/auth_mock/README.md',
    );
  }

  await launchSooqMerchantApp(pipelineResult);
}
