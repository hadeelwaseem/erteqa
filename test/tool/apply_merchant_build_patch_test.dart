import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/merchant_native_patch.dart';

void main() {
  test('patchAndroidGradleApplicationId updates applicationId only', () {
    final dir = Directory.systemTemp.createTempSync('gradle_patch_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final gradleFile = File('${dir.path}/build.gradle.kts')
      ..writeAsStringSync('''
android {
    namespace = "com.example.sooq_merchant"
    defaultConfig {
        applicationId = "com.example.sooq_merchant"
    }
}
''');

    patchAndroidGradleApplicationId(gradleFile, 'com.anasgoldenmer.shop');

    final content = gradleFile.readAsStringSync();
    expect(content, contains('namespace = "com.example.sooq_merchant"'));
    expect(content, contains('applicationId = "com.anasgoldenmer.shop"'));
    expect(content, isNot(contains('namespace = "com.anasgoldenmer.shop"')));
  });
}
