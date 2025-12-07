import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:healthcare/config_/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhrSharingService {
  // Singleton pattern (optional)
  PhrSharingService._privateConstructor();
  static final PhrSharingService instance = PhrSharingService._privateConstructor();

  final String shareUrl = '${ApiConfig.baseUrl}/phr/share-data';

  Future<void> shareData({
    required String patientId,
    required String doctorId,
    required List<Map<String, dynamic>> vitals,
    required List<Map<String, dynamic>> labs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      // Build payload (match Angular payload)
      final payload = {
        "patientId": int.tryParse(patientId) ?? 0,
        "doctorId": int.tryParse(doctorId) ?? 0,
        "sharedAt": DateTime.now().toIso8601String(),
        "vitals": vitals.map((v) {
          return {
            "vitalName": v["vitalName"],
            "vitalTypeName": v["vitalTypeName"],
            "value": v["value"],
            "date": v["date"],
            "time": v["time"],
            "isCritical": v["isCritical"] ?? false,
          };
        }).toList(),
        "labs": labs.map((l) {
          return {
            "reportName": l["reportName"],
            "fieldName": l["fieldName"],
            "value": l["value"],
            "date": l["date"],
            "time": l["time"],
            "isCritical": l["isCritical"] ?? false,
            "unit": l["unit"] ?? "",
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse(shareUrl),
        headers: {
          "Content-Type": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print("✅ Data shared successfully");
      } else {
        print("❌ Failed to share data: ${response.statusCode}");
        throw Exception("Failed to share data: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Share data error: $e");
      rethrow;
    }
  }
}
