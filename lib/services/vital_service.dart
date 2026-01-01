import 'dart:convert';
import 'package:healthcare/config_/api_config.dart';

import 'package:healthcare/models/vital_model.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class VitalsService {
  final String baseUrl = ApiConfig.baseUrl;



Future<List<VitalRecord>> getVitalsByPatient(String patientId) async {
  final uri = Uri.parse('$baseUrl/vitals/by-patient/$patientId');

  final prefs = await SharedPreferences.getInstance();
  final cookie = prefs.getString('session_cookie');

  final headers = {
    'Content-Type': 'application/json',
    if (cookie != null) 'Cookie': cookie,
  };

  final resp = await http.get(uri, headers: headers);

  if (resp.statusCode == 200) {
    final body = jsonDecode(resp.body);
    final vitalsArray =
        (body is Map && body['vitals'] is List) ? body['vitals'] as List : <dynamic>[];
    return vitalsArray.map((e) => VitalRecord.fromJson(e as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load vitals: ${resp.statusCode}');
  }
}


  // Future<List<VitalRecord>> getVitalsByPatient(String patientId) async {
  //   final uri = Uri.parse('$baseUrl/vitals/by-patient/$patientId');
  //   final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
  //   if (resp.statusCode == 200) {
  //     final body = jsonDecode(resp.body);
  //     final vitalsArray = (body is Map && body['vitals'] is List) ? body['vitals'] as List : <dynamic>[];
  //     return vitalsArray.map((e) => VitalRecord.fromJson(e as Map<String, dynamic>)).toList();
  //   } else {
  //     throw Exception('Failed to load vitals: ${resp.statusCode}');
  //   }
  // }

  Future<void> submitVitals(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/submitVitals');
    final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    if (resp.statusCode != 200) throw Exception('Failed to submit vitals: ${resp.statusCode}');
  }

  Future<void> deleteObservedVital(int obsVId) async {
  final prefs = await SharedPreferences.getInstance();
  final cookie = prefs.getString('session_cookie');

  final resp = await http.delete(
    Uri.parse('$baseUrl/vitals/observed/$obsVId'),
    headers: {
      'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    },
  );

  if (resp.statusCode != 200) {
    throw Exception('Delete failed');
  }
}
Future<void> updateObservedVital({
  required int obsVId,
  required num value,
  required String date,
  required String time,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final cookie = prefs.getString('session_cookie');

  final payload = {
    "obsVId": obsVId,
    "value": value,
    "date": date,
    "time": time,
  };

  final resp = await http.put(
    Uri.parse('$baseUrl/vitals/observed'),
    headers: {
      'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    },
    body: jsonEncode(payload),
  );

  if (resp.statusCode != 200) {
    throw Exception('Update failed');
  }
}

}
