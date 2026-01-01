import 'dart:convert';
import 'package:healthcare/config_/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecommendService {
  final String baseUrl = ApiConfig.baseUrl;

  /// Send report recommendation
  Future<void> recommendReports(
    int patientId,
    List<int> reportIds,
    String message,
    int doctorId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final url = Uri.parse('$baseUrl/recommend/save');
    final body = jsonEncode({
      'patientId': patientId,
      'reportIds': reportIds,
      'message': message,
      'doctorId': doctorId,
    });

    print('🔹 recommendReports URL: $url');
    print('🔹 recommendReports BODY: $body');
    print('🔹 recommendReports COOKIE: $cookie');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie, // include cookie
      },
      body: body,
    );

    print('🔹 recommendReports RESPONSE STATUS: ${response.statusCode}');
    print('🔹 recommendReports RESPONSE BODY: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send recommendation');
    }
  }
}
