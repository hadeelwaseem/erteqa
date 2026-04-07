// import 'dart:convert';
// import 'package:flutter/services.dart';
// import 'package:sooq_merchant/core/enums/component_type.dart';
// import 'app_config.dart';
// import 'screen_config.dart';
// import 'component_config.dart';

// //TODO: need a check
// abstract class ConfigLoader {
//   Future<AppConfig> load();
// }

// class JsonConfigLoader implements ConfigLoader {
//   final String assetPath;

//   const JsonConfigLoader({required this.assetPath});

//   @override
//   Future<AppConfig> load() async {
//     final String jsonString = await rootBundle.loadString(assetPath);
//     final Map<String, dynamic> json = jsonDecode(jsonString);

//     return _parseAppConfig(json);
//   }

//   // AppConfig _parseAppConfig(Map<String, dynamic> json) {
//   //   return AppConfig(
//   //     appName: json['appName'] as String,
//   //     bundleId: json['bundleId'] as String,
//   //     screens: (json['screens'] as List)
//   //         .map(
//   //           (screenJson) =>
//   //               _parseScreenConfig(screenJson as Map<String, dynamic>),
//   //         )
//   //         .toList(),
//   //   );
//   // }

//   // ScreenConfig _parseScreenConfig(Map<String, dynamic> json) {
//   //   return ScreenConfig(
//   //     id: json['id'] as String,
//   //     components: (json['components'] as List)
//   //         .map(
//   //           (componentJson) =>
//   //               _parseComponentConfig(componentJson as Map<String, dynamic>),
//   //         )
//   //         .toList(),
//   //   );
//   // }

//   // ComponentConfig _parseComponentConfig(Map<String, dynamic> json) {
//   //   final typeString = json['type'] as String;
//   //   final type = ComponentType.values.firstWhere(
//   //     (e) => e.name == typeString,
//   //     orElse: () => throw ArgumentError('Unknown component type: $typeString'),
//   //   );

//   //   return ComponentConfig(
//   //     type: type,
//   //     properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
//   //   );
//   // }

// }
