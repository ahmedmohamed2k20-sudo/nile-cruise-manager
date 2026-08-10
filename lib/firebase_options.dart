import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPK1IGv0FJBF3s_88PWebpeY3rTOaoQMk',
    appId: '1:258353555803:android:a2b74f3169cc0c1002d27e',
    messagingSenderId: '258353555803',
    projectId: 'nile-cruise-manager-1392d',
    storageBucket: 'nile-cruise-manager-1392d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAPK1IGv0FJBF3s_88PWebpeY3rTOaoQMk',
    appId: '1:258353555803:ios:a2b74f3169cc0c1002d27e',
    messagingSenderId: '258353555803',
    projectId: 'nile-cruise-manager-1392d',
    storageBucket: 'nile-cruise-manager-1392d.firebasestorage.app',
    iosBundleId: 'com.example.nileCruiseManager',
  );
}
