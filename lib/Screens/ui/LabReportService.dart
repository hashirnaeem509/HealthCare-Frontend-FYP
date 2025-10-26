// 📦 IMPORTS
import 'dart:convert';
import 'dart:io';
import 'package:healthcare/Screens/ui/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LabReportService {
  final String baseUrl = '${ApiConfig.baseUrl}/lab/reports';

  // 🧩 1️⃣ Get All Lab Tests
  Future<List<dynamic>> getLabTests() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.get(
      Uri.parse('$baseUrl/lab-tests'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load lab tests: ${response.statusCode}');
    }
  }

  // 🧩 2️⃣ Get Fields by Test (Updated for Map response)
  Future<List<dynamic>> getFieldsByTest(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.post(
      Uri.parse('$baseUrl/fields'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie,
      },
      body: jsonEncode({
        "fieldName": "",
        "labId": testId,
        "labTest": {"labTestId": testId},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 🔹 Convert Map<String,dynamic> to List<Map<String,dynamic>>
      if (data is Map<String, dynamic>) {
        final List<Map<String, dynamic>> fields = [];
        data.forEach((key, value) {
          if (key.trim().isEmpty) return; // ignore empty keys
          fields.add({
            'fieldName': key,
            'value': value?.toString() ?? '',
          });
        });
        return fields;
      }

      if (data is List) return data;

      throw Exception("Unexpected data format from backend");
    } else {
      throw Exception('Failed to load fields: ${response.statusCode}');
    }
  }

  // 🧩 3️⃣ Save Manual Report
  Future<String> saveManualReport(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.post(
      Uri.parse('$baseUrl/save-report'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('Manual report save failed: ${response.statusCode}');
    }
  }

  // 🧩 4️⃣ Upload & OCR Scan (Improved Upload)
  Future<Map<String, dynamic>> scanOCRReport(File file, int labTestId) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final uri = Uri.parse('$baseUrl/ocr-upload/$labTestId');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        if (cookie != null) 'Cookie': cookie,
      });

    // 🔍 Debug Logs
    print("📡 Uploading to: $uri");
    print("📦 File: ${file.path}");
    print("🍪 Cookie: $cookie");

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print("📥 Status: ${response.statusCode}");
    print("📜 Response: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {

      return jsonDecode(responseBody);
    } else {
      
      throw Exception(
          'OCR upload failed → ${response.statusCode}\nResponse: $responseBody');
    }
  }

  // ✅ Helper for UI calls
  Future<Map<String, dynamic>> uploadAndExtractOCR(File file, int labTestId) {
    return scanOCRReport(file, labTestId);
  }
}
