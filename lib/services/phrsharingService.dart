import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/config_/api_config.dart';

class PhrSharingService {
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

      // 🔥 EXACT SAME PAYLOAD AS ANGULAR
      final payload = {
        "patientId": int.parse(patientId),
        "doctorId": int.parse(doctorId),
        "sharedAt": DateTime.now().toIso8601String(),

        "vitals": vitals.map((v) {
          return {
            "vitalName": v["vitalName"],
            "vitalTypeName": v["vitalTypeName"],
            "value": v["value"],
            "date": v["date"],
            "time": v["time"],
            "isCritical": v["isCritical"] ?? false
          };
        }).toList(),

        // 🔥 MATCHING ANGULAR EXACTLY  
        "labs": labs.map((l) {
          return {
            "reportId": l["reportId"],
            "reportName": l["reportName"],
            "date": l["reportDate"],
            "time": l["reportTime"] ?? "00:00:00"
          };
        }).toList()
      };

      final response = await http.post(
        Uri.parse(shareUrl),
        headers: {
          "Content-Type": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to share data: ${response.statusCode}");
      }

      print("✅ Data shared successfully");
    } catch (e) {
      print("❌ Error during share: $e");
      rethrow;
    }
  }
}
