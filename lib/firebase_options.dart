import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123456789:web:abcdef',
    messagingSenderId: '123456789',
    projectId: 'aurora-2b8f4',
    authDomain: 'aurora-2b8f4.firebaseapp.com',
    storageBucket: 'aurora-2b8f4.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123456789:android:abcdef',
    messagingSenderId: '123456789',
    projectId: 'aurora-2b8f4',
    storageBucket: 'aurora-2b8f4.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123456789:ios:abcdef',
    messagingSenderId: '123456789',
    projectId: 'aurora-2b8f4',
    storageBucket: 'aurora-2b8f4.appspot.com',
    iosBundleId: 'com.example.aiTherapyTeteocan',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123456789:macos:abcdef',
    messagingSenderId: '123456789',
    projectId: 'aurora-2b8f4',
    storageBucket: 'aurora-2b8f4.appspot.com',
    iosBundleId: 'com.example.aiTherapyTeteocan',
  );
}
