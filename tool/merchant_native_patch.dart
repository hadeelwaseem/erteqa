import 'dart:io';

/// Patches Android [applicationId] only; leaves [namespace] unchanged so
/// [MainActivity] in `com.example.sooq_merchant` keeps resolving.
void patchAndroidGradleApplicationId(File file, String bundleId) {
  var content = file.readAsStringSync();
  content = content.replaceAll(
    RegExp(r'applicationId\s*=\s*"[^"]*"'),
    'applicationId = "$bundleId"',
  );
  file.writeAsStringSync(content);
}
