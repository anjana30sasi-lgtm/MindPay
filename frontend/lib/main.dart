import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
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
