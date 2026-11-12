import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'plant_controller.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plant_profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/pump_control_screen.dart';
import 'screens/ai_prediction_screen.dart';

// Default firmware plant ID used only if the user has not created one yet.
// Screens use PlantController.selectedPlantId, not this constant.
const String kDefaultPlantId = 'plant1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (_) {
    // Persistence may already be enabled on some platforms.
  }
  runApp(const SmartPlantCareApp());
}

class SmartPlantCareApp extends StatelessWidget {
  const SmartPlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      builder: (context, child) => AuthPlantBinder(child: child ?? const SizedBox.shrink()),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/plant-profile': (context) => const PlantProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/pump-control': (context) => const PumpControlScreen(),
        '/ai-prediction': (context) => const AiPredictionScreen(),
      },
    );
  }
}

/// Decides whether to show Login or Home based on auth state, and registers
/// the FCM device token for push notifications (FR-06) once logged in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _registerFcmToken(String uid) async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // Stored under users/{uid}.fcmToken - read by the onReadingCreated
        // Cloud Function to send push notifications (FR-06).
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Non-fatal: app still works without push notifications.
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          _registerFcmToken(snapshot.data!.uid);
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
