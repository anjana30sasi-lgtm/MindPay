import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
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
      home: const HomeScreen(),
    );
  }
}
