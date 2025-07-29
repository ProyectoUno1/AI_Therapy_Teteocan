import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart'; 

class SplashScreen extends StatelessWidget { 
  const SplashScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF82C4C3),
      body: Center(
        child: Lottie.asset("assets/logoAurora.json"),
      ),
    );
  }
}