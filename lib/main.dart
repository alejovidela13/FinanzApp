import 'package:flutter/material.dart';
import 'screens/main_nav_screen.dart';

void main() {
  runApp(const FinanzApp());
}

class FinanzApp extends StatelessWidget {
  const FinanzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanzApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const MainNavScreen(),
    );
  }
}