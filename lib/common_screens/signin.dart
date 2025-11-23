import 'package:flutter/material.dart';
import 'package:healthcare/common_screens/profile.dart';
import 'package:healthcare/Screens/doctor/doctordashboard.dart';
import 'package:healthcare/common_screens/registration.dart';
import 'package:healthcare/Screens/patient/patientdashborad.dart';
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

  // ---------------- LOGIN FUNCTION ----------------
  Future<void> _loginUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter username and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.loginUser(
        username: username,
        password: password,
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        final role = (result['role'] ?? '').toString().toUpperCase();
        final userId = result['userId']?.toString() ?? '';
        final profileUrl = result['checkProfileUrl'];

        print(" Login Success → Role: $role | UserId: $userId");

        final exists = await _authService.checkProfileExists(profileUrl);

        if (exists) {
          // Go to Dashboard
          if (role == "PATIENT") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Patientdashborad()),
            );
          } else if (role == "DOCTOR") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DoctorDashboard()),
            );
          } else {
            _showSnackBar("Unknown role: $role");
          }
        } else {
          // Go to Profile Creation Page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(role: role, userId: userId),
            ),
          );
        }
      } else {
        _showSnackBar(result['message'] ?? "Login failed");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error: $e");
    }
  }

  // ---------------- SNACKBAR ----------------
  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
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
              const Icon(
                Icons.account_circle_outlined,
                size: 50,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 10),
              const Text(
                "Sign In",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Username Field
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Username',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                  hintText: 'Password',
                  border: const UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 40),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53B2E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 15,
                  ),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),

              // Signup Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Registration()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53B2E8),
                  //  foregroundColor: const Color(0xFF53B2E8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  //side: const BorderSide(color: Color(0xFF53B2E8), width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 75,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Text
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Registration()),
                  );
                },
                child: const Text(
                  "Don’t have an account? Sign up",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
