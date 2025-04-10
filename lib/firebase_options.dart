// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8m6x8RmMyxPpViSkUQ9ChLBXiYEtqjIc',
    appId: '1:758257668487:android:e9d34abf8456bfb6ab8322',
    messagingSenderId: '758257668487',
    projectId: 'macromash-22723',
    storageBucket: 'macromash-22723.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3W_RVkdRlp6uIQeXhBd9hfD2ITgUmmkI',
    appId: '1:758257668487:ios:cc1ccdabe25fa05cab8322',
    messagingSenderId: '758257668487',
    projectId: 'macromash-22723',
    storageBucket: 'macromash-22723.firebasestorage.app',
    iosBundleId: 'com.example.macroCalculator',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC3W_RVkdRlp6uIQeXhBd9hfD2ITgUmmkI',
    appId: '1:758257668487:ios:cc1ccdabe25fa05cab8322',
    messagingSenderId: '758257668487',
    projectId: 'macromash-22723',
    storageBucket: 'macromash-22723.firebasestorage.app',
    iosBundleId: 'com.example.macroCalculator',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDb2tn21qwdNMil7pU19S-s9TR4tR22NpQ',
    appId: '1:758257668487:web:9bd967e114b95376ab8322',
    messagingSenderId: '758257668487',
    projectId: 'macromash-22723',
    authDomain: 'macromash-22723.firebaseapp.com',
    storageBucket: 'macromash-22723.firebasestorage.app',
    measurementId: 'G-8JPKTRK9D8',
  );
}
