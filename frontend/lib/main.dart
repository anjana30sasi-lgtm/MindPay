import 'package:flutter/material.dart';

import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_questions_screen.dart';
import 'services/user_preferences_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/user_preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: const StartupRouter(),
    );
  }
}

class StartupRouter extends StatelessWidget {
  const StartupRouter({super.key});

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    final onboarded = await UserPreferencesService.hasOnboarded();

    if (user == null) {
  return const WelcomeScreen();
}

    if (!onboarded) {
      return const OnboardingQuestionsScreen();
    }

    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: MindColors.forest,
            body: Center(
              child: CircularProgressIndicator(
                color: MindColors.pauseAmber,
              ),
            ),
          );
        }

        return snapshot.data!;
      },
    );
  }
}