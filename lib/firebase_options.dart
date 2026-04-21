// ignore_for_file: type=lint
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA9EnVHGG_AktiBOu_SXqN2LR1JSTVI1ug',
    appId: '1:934475687484:web:796f6c18e21ebfd25c4539',
    messagingSenderId: '934475687484',
    projectId: 'flutter2-66192',
    authDomain: 'flutter2-66192.firebaseapp.com',
    storageBucket: 'flutter2-66192.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-tFWVdIjkV-UOX6yFiql-vBkVd3Y3Zzc',
    appId: '1:934475687484:android:6b08f5c0acb8829e5c4539',
    messagingSenderId: '934475687484',
    projectId: 'flutter2-66192',
    storageBucket: 'flutter2-66192.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDT7fBfsBDiFXKnk07kyt3ARFoC9Dr2biE',
    appId: '1:934475687484:ios:ec888f01d45519f95c4539',
    messagingSenderId: '934475687484',
    projectId: 'flutter2-66192',
    storageBucket: 'flutter2-66192.firebasestorage.app',
    androidClientId: '934475687484-okunudjh9of8fglhc0ga5slnl4l4u4ak.apps.googleusercontent.com',
    iosClientId: '934475687484-lnqtom2a2knv5vsngrsg6vv0369pj5gj.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutter5',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDT7fBfsBDiFXKnk07kyt3ARFoC9Dr2biE',
    appId: '1:934475687484:ios:ec888f01d45519f95c4539',
    messagingSenderId: '934475687484',
    projectId: 'flutter2-66192',
    storageBucket: 'flutter2-66192.firebasestorage.app',
    androidClientId: '934475687484-okunudjh9of8fglhc0ga5slnl4l4u4ak.apps.googleusercontent.com',
    iosClientId: '934475687484-lnqtom2a2knv5vsngrsg6vv0369pj5gj.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutter5',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA9EnVHGG_AktiBOu_SXqN2LR1JSTVI1ug',
    appId: '1:934475687484:web:49423c9e3063a9955c4539',
    messagingSenderId: '934475687484',
    projectId: 'flutter2-66192',
    authDomain: 'flutter2-66192.firebaseapp.com',
    storageBucket: 'flutter2-66192.firebasestorage.app',
  );
}
