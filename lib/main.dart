import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app.dart';
import 'services/sensor/simulator_source.dart';
import 'services/sensor_simulator_service.dart';
import 'di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();

  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized');

    // Sign in anonymously so Firestore writes are linked to a user
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      debugPrint('Signed in anonymously: ${auth.currentUser?.uid}');
    } else {
      debugPrint('Already signed in: ${auth.currentUser?.uid}');
    }
  } catch (e) {
    debugPrint('Firebase not configured, running in offline mode: $e');
  }

  await di.init();

  // Load WESAD data for both simulator implementations
  await di.sl<SimulatorSource>().loadWesadData();
  await di.sl<SensorSimulatorService>().loadWesadData();

  runApp(
    const ProviderScope(
      child: StressMonitorApp(),
    ),
  );
}
