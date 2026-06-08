// Copy this file to lib/firebase_options.dart after configuring Firebase for your project.
// Do not commit lib/firebase_options.dart to source control.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'FirebaseOptions have not been configured. '
      'Copy firebase_options.example.dart to firebase_options.dart or run the FlutterFire CLI to generate it.',
    );
  }
}
