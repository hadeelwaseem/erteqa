//   import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:lms_student/firebase_options.dart';

// Future<String?> initFirebase() async {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );

//     await FirebaseMessaging.instance.requestPermission();
//  FirebaseAnalytics.instance;
// // 
//     FirebaseMessaging messaging = FirebaseMessaging.instance;
//     String? firebaseToken = await messaging.getToken();
//     return firebaseToken;
//   }