import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = 'http://172.16.21.246:8080';

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
      'role': role,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Registration successful'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Something went wrong'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network or server issue: $e'};
    }
  }

  //  Login (with session cookie + extra data save)
  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    final String apiUrl = '$baseUrl/auth/login';

    final Map<String, dynamic> loginData = {
      'username': username,
      'password': password,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // 🔹 Cookie nikalna aur save karna
        final cookie = response.headers['set-cookie'];
        final prefs = await SharedPreferences.getInstance();

        if (cookie != null) {
          await prefs.setString('session_cookie', cookie);
        }

        // 🔹 Extra data save karna (role, userid)
        if (responseBody['role'] != null) {
          await prefs.setString('role', responseBody['role'].toUpperCase());
        }
        if (responseBody['userId'] != null) {
          await prefs.setString('userId', responseBody['userId'].toString());
        }

        // 🔹 Role check karke profile URL set karna
        final savedRole = prefs.getString('role');
        final userId = prefs.getString('userId');
        String checkProfileUrl = '';

        if (savedRole == 'PATIENT') {
          checkProfileUrl = '$baseUrl/patient/profile/$userId';
          print("Patient Profile URL: $checkProfileUrl");
          // yaha navigate logic aa sakta hai
        } else if (savedRole == 'DOCTOR') {
          checkProfileUrl = '$baseUrl/doctor/profile/$userId';
          print("Doctor Profile URL: $checkProfileUrl");
          // yaha navigate logic aa sakta hai
        } else {
          print("Role not set or invalid");
        }

        return {
          'success': true,
          'message': responseBody['message'] ?? 'Login successful',
          'role': responseBody['role'].toUpperCase() ?? '',
          'checkProfileUrl': checkProfileUrl, // ✅ return bhi kar raha hu
        };
      } else {
        final responseBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Invalid credentials'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network or server issue: $e'};
    }
  }
  Future<bool> checkProfileExists(String url) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie, // session cookie bhejni zaroori hai
      },
    );

    if (response.statusCode == 200) {
      return true; // ✅ profile mil gayi
    } else {
      return false; // ❌ profile nahi mili
    }
  } catch (e) {
    print("Profile check error: $e");
    return false;
  }
}

}
