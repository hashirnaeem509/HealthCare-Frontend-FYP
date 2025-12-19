import 'dart:convert';
import 'package:healthcare/config_/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionService {
  final String baseUrl = '${ApiConfig.baseUrl}/prescriptions';

  Future<bool> savePrescription({
    required int doctorId,
    required int patientId,
    required String medicine,
    required String dosage,
    String? notes,
  }) async {
    final String url = '$baseUrl/save';

    final payload = {
      'doctorId': doctorId,
      'patientId': patientId,
      'medicines': [
        {
          'name': medicine,
          'dosage': dosage,
        }
      ],
      'notes': notes ?? '',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error saving prescription: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }
}
