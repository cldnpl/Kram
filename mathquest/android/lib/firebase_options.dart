import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCu9GypnmcirlV1cgaMDc3FpIJawQpJib8',
    appId: '1:663402131003:android:739b2f309cd48e9a67b61e',
    messagingSenderId: '663402131003',
    projectId: 'the-big-5-15035',
    storageBucket: 'the-big-5-15035.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD1r7HQsjJGn3bs7ZOOh7hIHrEwso2wB6A',
    appId: '1:663402131003:ios:7fa61f2175461a6767b61e',
    messagingSenderId: '663402131003',
    projectId: 'the-big-5-15035',
    storageBucket: 'the-big-5-15035.firebasestorage.app',
    iosClientId: '663402131003-9mm4m1tmkmi34j7tv4ru8u03ldmumm96.apps.googleusercontent.com',
    iosBundleId: 'com.kram.math',
  );
}
