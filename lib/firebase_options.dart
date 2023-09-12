// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyAN6tJVkH9lej2w7_-3ERDii7lQEo8KVhY',
    appId: '1:760270134436:web:38fb93cc36c9e2404dda31',
    messagingSenderId: '760270134436',
    projectId: 'todo-51e63',
    authDomain: 'todo-51e63.firebaseapp.com',
    storageBucket: 'todo-51e63.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHe-C1RYbgwD5X64wYKWHgNtJkJ5Aen3M',
    appId: '1:760270134436:android:6667192c1efc6f074dda31',
    messagingSenderId: '760270134436',
    projectId: 'todo-51e63',
    storageBucket: 'todo-51e63.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDn3VN5GGhwNJrrMkzjHSkvnkzWTYITQrA',
    appId: '1:760270134436:ios:b22f4d710088e4d24dda31',
    messagingSenderId: '760270134436',
    projectId: 'todo-51e63',
    storageBucket: 'todo-51e63.appspot.com',
    androidClientId: '760270134436-cmhrqk2pb70cd3nc65k69lv1cpe4paeg.apps.googleusercontent.com',
    iosClientId: '760270134436-lmfhuu81pn59ld65tcm1ad413r0vc503.apps.googleusercontent.com',
    iosBundleId: 'com.example.toDo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDn3VN5GGhwNJrrMkzjHSkvnkzWTYITQrA',
    appId: '1:760270134436:ios:c1e779dc4e72501c4dda31',
    messagingSenderId: '760270134436',
    projectId: 'todo-51e63',
    storageBucket: 'todo-51e63.appspot.com',
    androidClientId: '760270134436-cmhrqk2pb70cd3nc65k69lv1cpe4paeg.apps.googleusercontent.com',
    iosClientId: '760270134436-v59lrki4j0tbcmq2uef9lpfed54kje9g.apps.googleusercontent.com',
    iosBundleId: 'com.example.toDo.RunnerTests',
  );
}
