import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const HydrationNutritionApp());
}

class HydrationNutritionApp extends StatelessWidget {
  const HydrationNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelacak Hidrasi dan Nutrisi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      ),
      home: const LoginScreen(),
    );
  }
}
