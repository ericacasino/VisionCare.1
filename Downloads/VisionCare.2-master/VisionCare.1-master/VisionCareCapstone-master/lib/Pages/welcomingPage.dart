import 'package:flutter/material.dart';
import '../main.dart'; // Import to access the global navigatorKey

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      // Use the global navigator key to ensure navigation works
      navigatorKey.currentState?.pushReplacementNamed('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF80ED99),
              Color(0xFF80ED99),
              Color(0xFF80ED99),
              Color(0xFF80ED99),
              Color(0xFF45DFB1),
              Color(0xFF45DFB1),
              Color(0xFF0AD1C8),
              Color(0xFF0AD1C8),
              Color(0xFF14919B),
              Color(0xFF0B6477),
              Color(0xFF213A57),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              SizedBox(
                height: 379,
                width: 325,
                child: Image.asset('Assets/images/Logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 30),
              // Added CircularProgressIndicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
