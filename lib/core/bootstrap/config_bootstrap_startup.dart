import 'package:flutter/material.dart';

import '../../app/launch_sooq_merchant_app.dart';
import '../../engine/config_pipeline_result.dart';

/// Re-runs DI + router setup after a successful config retry.
Future<void> restartWithPipelineResult(ConfigPipelineResult result) async {
  WidgetsFlutterBinding.ensureInitialized();
  await launchSooqMerchantApp(result);
}
