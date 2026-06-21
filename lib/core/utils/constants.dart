import 'package:flutter/material.dart';

// const kBaseUrl = 'http://192.168.137.8:8000/api';
// const kBaseUrl = 'http://10.0.2.2:8000/api';
/// Deprecated: use [NetworkConfig.baseUrl] from service locator.
const kBaseUrl = 'https://shopengine-production-c68b.up.railway.app';

/// Deprecated: use [NetworkConfig.assetBaseUrl].
final kBaseUrlAsset = kBaseUrl.split('/api')[0];

// const kWebSocketUrl = 'ws://jaramana-clinic-center.onrender.com/ws';
const Color primaryColor = Color(0xff4A4BB3);
const Color secondaryColor = Color(0xff4A4BB3);
const Color scaffoldColor = Color(0xFFF0F0F0);
const Color blueColor = Color(0xff1F237A);
const blueGredient = [blueColor, blueColor];

const double kProfileHorizontalPadding = 20.0;
const double kMedicalCardSize = 120.0;
const double kMedicalCardSpacing = 16.0;

const double kEditProfileHorizontalPadding = 20.0;
const double kEditProfileSectionSpacing = 28.0;
const double kEditProfileFieldSpacing = 16.0;
const double kEditProfileAvatarRadius = 55.0;
