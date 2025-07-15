import 'package:flutter/material.dart';
import 'screens/subnet_calculator_screen.dart';

void main() {
  runApp(const SubnetCalculatorApp());
}

class SubnetCalculatorApp extends StatelessWidget {
  const SubnetCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora VLSM',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ), 
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const SubnetCalculatorScreen(),
    );
  }
}