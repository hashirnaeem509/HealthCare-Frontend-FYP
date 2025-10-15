import 'dart:convert';
import 'package:healthcare/Screens/ui/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  //final String baseUrl = 'http://192.168.43.233:8080';
  final String baseUrl = ApiConfig.baseUrl;

  // ---------------- REGISTER ----------------
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final String apiUrl = '$baseUrl/auth/register';

    final Map<String, dynamic> userData = {
      'username': username,
      'email': email,
      'password': password,
      'role': role.toUpperCase(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network or server issue: $e'};
    }
  }

  // ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    final String apiUrl = '$baseUrl/auth/login';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Save Cookie
        final cookie = response.headers['set-cookie'];
        final prefs = await SharedPreferences.getInstance();
        if (cookie != null) await prefs.setString('session_cookie', cookie);

        // Save Role + UserId
        final role = (responseBody['role'] ?? '').toUpperCase();
        final userId = responseBody['userId']?.toString();
        if (role.isNotEmpty) await prefs.setString('role', role);
        if (userId != null) await prefs.setString('userId', userId);

        if (role == "PATIENT") {
          await prefs.setInt('patientId', int.parse(userId!));
          print("🔹 Patient ID: $userId");
        } else if (role == "DOCTOR") {
          await prefs.setInt('doctorId', int.parse(userId!));
          print("🔹 Doctor ID: $userId");
        }

        //  Profile URL (for existence check)
        String checkProfileUrl = '';
        if (role == 'PATIENT') checkProfileUrl = '$baseUrl/patient/$userId';
        if (role == 'DOCTOR') checkProfileUrl = '$baseUrl/doctor/$userId';

        return {
          'success': true,
          'message': responseBody['message'] ?? 'Login successful',
          'role': role,
          'userId': userId,
          'checkProfileUrl': checkProfileUrl,
        };
      } else {
        final responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network or server issue: $e'};
    }
  }

  // ---------------- PROFILE CHECK ----------------
  Future<bool> checkProfileExists(String? url) async {
    if (url == null || url.isEmpty) {
      print(" checkProfileExists: URL is empty");
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      print("📡 Profile check status: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print(" Profile check error: $e");
      return false;
    }
  }
}
