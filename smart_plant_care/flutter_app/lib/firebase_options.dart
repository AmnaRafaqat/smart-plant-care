// Firebase options copied from the existing prototype project
// (smart-plant-care-342d6). Do not replace these with placeholder values.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Add the app in Firebase Console and regenerate firebase_options.dart.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBX_ozxtICloTD1zf-zKPcKQk0chpVq7FY',
    appId: '1:1003267685339:web:4221a43ffa243565d0c5fe',
    messagingSenderId: '1003267685339',
    projectId: 'smart-plant-care-342d6',
    authDomain: 'smart-plant-care-342d6.firebaseapp.com',
    storageBucket: 'smart-plant-care-342d6.firebasestorage.app',
    databaseURL:
        'https://smart-plant-care-342d6-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBX_ozxtICloTD1zf-zKPcKQk0chpVq7FY',
    appId: '1:1003267685339:android:4221a43ffa243565d0c5fe',
    messagingSenderId: '1003267685339',
    projectId: 'smart-plant-care-342d6',
    storageBucket: 'smart-plant-care-342d6.firebasestorage.app',
    databaseURL:
        'https://smart-plant-care-342d6-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
