import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Ignore background init failures on builds without Firebase config.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // Allow app to boot even if Firebase isn't configured in this build.
  }

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await NotificationService.instance.init();
  }

  runApp(const TensorAlertsApp());
}

class TensorAlertsApp extends StatelessWidget {
  const TensorAlertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0A0A0A);
    const card = Color(0xFF121212);
    const green = Color(0xFF00FF9F);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tensor Alerts',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        cardColor: card,
        colorScheme: const ColorScheme.dark(
          primary: green,
          secondary: Color(0xFF00F0FF),
          tertiary: Color(0xFF8A2BE2),
          surface: card,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const HomeScreen(),
    );
  }
}
