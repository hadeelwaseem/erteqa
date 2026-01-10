import 'package:flutter/material.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    bodySmall: TextStyle(color: Colors.white),
  ),
  buttonTheme: const ButtonThemeData(buttonColor: Color(0xffebe6e0)),
  iconTheme: IconThemeData(color: primaryColor),

  // Adding ColorScheme
  colorScheme: ColorScheme(
    onPrimaryContainer: Color(0xffebe6e0),
    primary: primaryColor, // اللون الأساسي
    primaryContainer: primaryColor.withOpacity(0.7),
    secondary: Colors.white, // اللون الثانوي
    secondaryContainer: Colors.blueAccent,
    surface: Colors.white, // لون الخلفية
    error: Colors.red, // لون الأخطاء
    onPrimary: Colors
        .white, // اللون المستخدم مع الـ primary (النصوص على الخلفية الأساسية)
    onSecondary: Colors.grey[200]!, // اللون المستخدم مع الـ secondary
    onSurface: Colors.black, // اللون المستخدم مع خلفية الصفحة
    onError: Colors.white, // اللون المستخدم مع الأخطاء
    brightness: Brightness.light, // تحديد إذا كان الوضع ليلي أو نهاري
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  // Colors.white,
  scaffoldBackgroundColor: Color.fromARGB(255, 31, 31, 31),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepOrange,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  buttonTheme: ButtonThemeData(buttonColor: Colors.deepOrange),
  iconTheme: IconThemeData(color: Colors.white),
  colorScheme: ColorScheme.dark(
    onPrimaryContainer: Colors.black,
    primary: Colors.black45,
    onPrimary: Colors.white,
    secondary: primaryColor,
    onSecondary: Colors.grey[800]!, //استخدم لل navigatton
    surface: Color.fromARGB(
      255,
      39,
      38,
      38,
    ), // لون السطح مثل الحوارات أو الأوراق
    onSurface: Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
);
