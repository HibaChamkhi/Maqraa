// ============================================================================
//  Firebase configuration — TEMPLATE
// ----------------------------------------------------------------------------
//  ⚠️  REPLACE THIS FILE before running the app.
//  Run:  dart pub global activate flutterfire_cli
//        flutterfire configure
//  That command auto-generates this file with YOUR project's real keys and
//  also drops google-services.json (Android) + GoogleService-Info.plist (iOS).
//
//  The placeholder values below let the project compile, but Firebase calls
//  will fail at runtime until you regenerate this file.
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  // Values taken from android/app/google-services.json and
  // ios/Runner/GoogleService-Info.plist (project: maqraa-1add5).
  // NOTE: web reuses the Android API key. If you restricted that key in the
  // Google Cloud console, register a Web app in the Firebase console and run
  // `flutterfire configure` to get a dedicated web appId + browser key.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAthsPL2MKtMv0BA9fqhdW91SC3KIlb3lM',
    appId: '1:173216165827:web:bb67b838dec899614cd776',
    messagingSenderId: '173216165827',
    projectId: 'maqraa-1add5',
    authDomain: 'maqraa-1add5.firebaseapp.com',
    storageBucket: 'maqraa-1add5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAthsPL2MKtMv0BA9fqhdW91SC3KIlb3lM',
    appId: '1:173216165827:android:bb67b838dec899614cd776',
    messagingSenderId: '173216165827',
    projectId: 'maqraa-1add5',
    storageBucket: 'maqraa-1add5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBoqch-b9ZT3WFHZS400NGmWdlLpWRdmoI',
    appId: '1:173216165827:ios:110767486257fc804cd776',
    messagingSenderId: '173216165827',
    projectId: 'maqraa-1add5',
    storageBucket: 'maqraa-1add5.firebasestorage.app',
    iosBundleId: 'com.example.maqraa',
  );
}
