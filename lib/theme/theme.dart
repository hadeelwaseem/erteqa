import 'package:flutter/material.dart';
import 'package:sooq_merchant/constants.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kAppColor,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: kAppColor,
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    bodySmall: TextStyle(color: Colors.white),
  ),
  buttonTheme: const ButtonThemeData(buttonColor: Color(0xffebe6e0)),
  iconTheme: IconThemeData(color: kAppColor),

  // Adding ColorScheme
  colorScheme: ColorScheme(
    onPrimaryContainer: Color(0xffebe6e0),
    primary: kAppColor, // اللون الأساسي
    primaryContainer: kAppColor.withOpacity(0.7),
    secondary: Colors.white, // اللون الثانوي
    secondaryContainer: Colors.blueAccent,
    surface: Colors.white, // الخلفيات العادية مثل الـ cards
    background: Colors.white, // لون الخلفية
    error: Colors.red, // لون الأخطاء
    onPrimary: Colors
        .white, // اللون المستخدم مع الـ primary (النصوص على الخلفية الأساسية)
    onSecondary: Colors.grey[200]!, // اللون المستخدم مع الـ secondary
    onSurface: Colors.black, // اللون المستخدم مع الخلفيات السطحية
    onBackground: Color(0xfff8f7f4), // اللون المستخدم مع خلفية الصفحة
    onError: Colors.white, // اللون المستخدم مع الأخطاء
    brightness: Brightness.light, // تحديد إذا كان الوضع ليلي أو نهاري
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: kAppColor,
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
    secondary: kAppColor,
    onSecondary: Colors.grey[800]!, //استخدم لل navigatton
    surface: Color.fromARGB(
      255,
      39,
      38,
      38,
    ), // لون السطح مثل الحوارات أو الأوراق
    onSurface: Colors.white,
    background: Colors.grey[900]!,
    onBackground: Colors.grey[800]!,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
);
