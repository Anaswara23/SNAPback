import 'package:firebase_core/firebase_core.dart';

import '../core/utils/app_logger.dart';
import '../firebase_options.dart';

/// Initialises Firebase once and reports whether it succeeded.
class FirebaseBootstrapService {
  Future<bool> initialize() async {
    try {
      AppLogger.info('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase initialized successfully');
      return true;
    } catch (e, st) {
      AppLogger.error('Firebase initialization failed', e, st);
      return false;
    }
  }
}
