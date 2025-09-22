import 'package:flutter/material.dart';
import 'dart:async';
import 'Signin.dart'; // your next screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 5 second baad Signin screen pe navigate
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF53B2E8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Responsive logo image
            Flexible(
              child: Image.asset(
                "assets/images/logo.png",
                width: MediaQuery.of(context).size.width * 0.8, // 60% screen width
                height: MediaQuery.of(context).size.height * 0.6, // 30% screen height
                fit: BoxFit.contain, // maintain aspect ratio
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "HealthCare App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}
