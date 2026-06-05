import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5Knmn0PhsrM0mcxV9p7BxlIdiH0CG0-E',
    appId: '1:433992021327:web:1c0ba50f9f5c12bc31013a',
    messagingSenderId: '433992021327',
    projectId: 'financeapp-b0a10',
    authDomain: 'financeapp-b0a10.firebaseapp.com',
    storageBucket: 'financeapp-b0a10.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA5Knmn0PhsrM0mcxV9p7BxlIdiH0CG0-E',
    appId: '1:433992021327:web:1c0ba50f9f5c12bc31013a',
    messagingSenderId: '433992021327',
    projectId: 'financeapp-b0a10',
    storageBucket: 'financeapp-b0a10.firebasestorage.app',
  );
}
