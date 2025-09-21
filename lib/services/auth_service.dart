import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://192.168.0.101:8080';

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

 // 🔹 Login (without token)
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

        //  Backend se message + role expect karte hain
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Login successful',
          'role': responseBody['role'] ?? '', // Agar backend role bhejta hai
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
}
