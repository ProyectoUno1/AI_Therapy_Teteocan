import 'package:flutter/material.dart';
import 'package:ai_therapy_teteocan/screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aurora AI Therapy App',
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Roboto'),
      home: LoginScreen(),
    );
  }
}
