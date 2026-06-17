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

  // TODO: replace all REPLACE_ME values via `flutterfire configure`.

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnjMO5ItG9vw7SyFPeGfsGKJJ5bQ8Bq4s',
    appId: '1:173216165827:web:4738cf1a7529b7044cd776',
    messagingSenderId: '173216165827',
    projectId: 'maqraa-1add5',
    authDomain: 'maqraa-1add5.firebaseapp.com',
    storageBucket: 'maqraa-1add5.firebasestorage.app',
    measurementId: 'G-LCLT7410PJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAthsPL2MKtMv0BA9fqhdW91SC3KIlb3lM',
    appId: '1:173216165827:android:bb67b838dec899614cd776',
    messagingSenderId: '173216165827',
    projectId: 'maqraa-1add5',
    storageBucket: 'maqraa-1add5.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.example.maqraa',
  );
}
