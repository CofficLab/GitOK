import 'package:flutter/material.dart';
import 'package:gitok/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GitOK')),
        body: const HomeScreen(),
      ),
    );
  }
}
