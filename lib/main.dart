import 'package:flutter/material.dart';
//import 'package:healthcare/Screens/ui/signin.dart';
import 'package:healthcare/Screens/ui/splashscrren.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      
      home: const SplashScreen(),
    );
  }
}
