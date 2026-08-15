import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme.dart';
import 'screens/welcome_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Start the app
  runApp(const MindPayApp());
}

class MindPayApp extends StatelessWidget {
  const MindPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindPay',

      debugShowCheckedModeBanner: false,

      theme: MindTheme.theme,

      // Always start with the Welcome Screen
      home: const WelcomeScreen(),
    );
  }
}