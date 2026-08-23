import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/plant_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBX_ozxtICloTD1zf-zKPcKQk0chpVq7FY',
      appId: '1:1003267685339:web:4221a43ffa243565d0c5fe',
      messagingSenderId: '1003267685339',
      projectId: 'smart-plant-care-342d6',
      authDomain: 'smart-plant-care-342d6.firebaseapp.com',
      storageBucket: 'smart-plant-care-342d6.firebasestorage.app',
      databaseURL: 'https://smart-plant-care-342d6-default-rtdb.asia-southeast1.firebasedatabase.app',
    ),
  );
  runApp(const SmartPlantCareApp());
}

class SmartPlantCareApp extends StatelessWidget {
  const SmartPlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plant Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/plant-profile': (context) => const PlantProfileScreen(),
      },
    );
  }
}

/// Decides whether to show Login or Dashboard based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

