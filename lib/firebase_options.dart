// GENERATED MANUAL - geodos-25677
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web; // usa config web por defecto en web/escritorio
    }
  }

  // ANDROID (desde tu google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7IXIUzLO2s4Izxnzb3PKYzqDX1jtJV-M',
    appId: '1:184271838084:android:199a41a4b48b99c3605bd1',
    messagingSenderId: '184271838084',
    projectId: 'geodos-25677',
    storageBucket: 'geodos-25677.firebasestorage.app',
  );

  // WEB (desde tu config web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBW1ZLfb0m1z9Y45pmx0Y30r4k9oNa13Ug',
    appId: '1:184271838084:web:777a7542ac4833da605bd1',
    messagingSenderId: '184271838084',
    projectId: 'geodos-25677',
    authDomain: 'geodos-25677.firebaseapp.com',
    storageBucket: 'geodos-25677.firebasestorage.app',
  );
}

