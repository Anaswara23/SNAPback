import 'package:flutter/material.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('App main() started');
  runApp(const SnapbackRoot());
}
