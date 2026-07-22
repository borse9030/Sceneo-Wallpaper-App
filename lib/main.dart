import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  // Ensure binding is initialized before anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any errors during startup and show them instead of crashing silently
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('FlutterError: ${details.exception}');
      print('Stack: ${details.stack}');
    }
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) print('Firebase init error: $e');
  }

  // Initialize Hive for local storage
  try {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('favorites')) {
      await Hive.openBox('favorites');
    }
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
  } catch (e) {
    if (kDebugMode) print('Hive init error: $e');
  }

  // Initialize Workmanager for background tasks (Not supported on Web)
  if (!kIsWeb) {
    try {
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    } catch (e) {
      if (kDebugMode) print('Workmanager init error: $e');
    }
  }

  // Notification initialization moved to HomeScreen to avoid prompt during splash screen

  // Initialize AdMob (Not supported on Web)
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      if (kDebugMode) print('AdMob init error: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: SceneoApp(),
    ),
  );
}
