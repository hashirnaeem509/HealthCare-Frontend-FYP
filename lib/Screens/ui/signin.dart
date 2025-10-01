import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/doctor/ui/doctordashboard.dart';
import 'package:healthcare/Screens/ui/patientdashborad.dart';
import 'package:healthcare/Screens/ui/registration.dart';
import 'package:healthcare/Screens/ui/profile.dart';
import 'package:healthcare/services/auth_service.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _loginUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter username and password");
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.loginUser(username: username, password: password);

    setState(() => _isLoading = false);

    if (result['success']) {
      final role = result['role'] ?? '';
      final userId = result['userId'];
      final profileUrl = result['checkProfileUrl'];

      print("✅ Login Success → Role: $role, UserId: $userId");

      final exists = await _authService.checkProfileExists(profileUrl);

      if (exists) {
        // Go to Dashboard
        if (role == "PATIENT") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Patientdashborad()));
        } else if (role == "DOCTOR") {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorDashboard()));
        }
      } else {
        // Go to Profile Creation Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage(role: role, userId: userId ?? '')),
        );
      }
    } else {
      _showSnackBar(result['message']);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF53B2E8), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 50, color: Colors.blueAccent),
              const SizedBox(height: 10),
              const Text("Sign In", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Username',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  hintText: 'Password',
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53B2E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Registration())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53B2E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                  elevation: 5,
                ),
                child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Registration())),
                child: const Text(
                  "Don’t have account? Sign up",
                  style: TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
