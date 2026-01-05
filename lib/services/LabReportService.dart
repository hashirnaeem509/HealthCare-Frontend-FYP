
import 'dart:convert';
import 'dart:io';
import 'package:healthcare/config_/api_config.dart';
import 'package:http_parser/http_parser.dart';


import 'package:healthcare/models/labs_reports.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LabReportService {
  final String baseUrl = '${ApiConfig.baseUrl}/lab/reports';

 
 
Future<List<Map<String, dynamic>>> getPatientReports(String patientId) async {
  final prefs = await SharedPreferences.getInstance();
  final cookie = prefs.getString('session_cookie');

  final response = await http.get(
    Uri.parse('$baseUrl/lab/field-values/by-patient/$patientId'),
    headers: {
      'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);

    
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Failed to load patient reports: ${response.statusCode}');
  }
}

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
// Future<Map<String, dynamic>> getSingleLabReport(
//     String patientId, String reportId) async {
//   final res = await http.get(
//     Uri.parse('${ApiConfig.baseUrl}/patient/$patientId/lab-report/$reportId'),
//     headers: {"Accept": "application/json"},
//   );

//   if (res.statusCode == 200) {
//     return json.decode(res.body);
//   } else {
//     throw Exception("Failed to load lab report");
//   }
// }
// Future<Map<String, dynamic>> getLabReportById(String reportId) async {
//   final prefs = await SharedPreferences.getInstance();
//   final cookie = prefs.getString('session_cookie');

//   final url = '${ApiConfig.baseUrl}/lab-report/$reportId';

//   debugPrint("🌐 GET $url");
//   debugPrint("🍪 Cookie: $cookie");

//   final res = await http.get(
//     Uri.parse(url),
//     headers: {
//       "Accept": "application/json",
//       if (cookie != null) "Cookie": cookie,
//     },
//   );

//   debugPrint("⬅ Status Code: ${res.statusCode}");
//   debugPrint("⬅ Body: ${res.body}");

//   if (res.statusCode == 200) {
//     return jsonDecode(res.body);
//   } else {
//     throw Exception(
//         "API failed: ${res.statusCode} → ${res.body}");
//   }
// }




 
  Future<List<dynamic>> getFieldsByTest(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.get(
      Uri.parse('$baseUrl/lab-tests/$testId/fields'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data;
      } else if (data is Map<String, dynamic>) {
        return data.entries
            .map((e) => {"fieldName": e.key, "value": e.value})
            .toList();
      } else {
        throw Exception("Unexpected response format");
      }
    } else {
      throw Exception('Failed to load fields: ${response.statusCode}');
    }
  }


  Future<String> saveManualReport(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.post(
      Uri.parse('$baseUrl/manual'), 
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body.toString();
    } else {
      throw Exception(
        'Manual report save failed: ${response.statusCode} - ${response.body}',
      );
    }
  }
Future<bool> checkCritical({
  required int patientId,
  required int fieldId,
  required double value,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final cookie = prefs.getString('session_cookie');

  final response = await http.post(
    Uri.parse('$baseUrl/check-critical'),
    headers: {
      'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    },
    body: jsonEncode({
      'patientId': patientId,
      'fieldId': fieldId,
      'value': value,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as bool;
  } else {
    throw Exception('Critical check failed');
  }
}

  
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

    print(" Uploading to: $uri");
    print(" File: ${file.path}");
    print(" Cookie: $cookie");

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print(" Status: ${response.statusCode}");
    print(" Response: $responseBody");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception(
          'OCR upload failed → ${response.statusCode}\nResponse: $responseBody');
    }
  }

  
  Future<Map<String, dynamic>> uploadAndExtractOCR(File file, int labTestId) {
    return scanOCRReport(file, labTestId);
  }

  Future<List<PatientReportSummaryDTO>> getPatientReportSummaries(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    print("Fetching reports → patientId: $patientId, cookie: $cookie");

    final response = await http.get(
      Uri.parse('$baseUrl/by-patient/$patientId/summary'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie, 
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PatientReportSummaryDTO.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load reports: ${response.statusCode}');
    }
  }
Future<String> saveManualReportWithImage(
  Map<String, dynamic> reportData,
  File? image,
) async {
  final prefs = await SharedPreferences.getInstance();
  final cookie = prefs.getString('session_cookie');

  final uri = Uri.parse('$baseUrl/manual');
  final request = http.MultipartRequest('POST', uri);

  if (cookie != null) {
    request.headers['Cookie'] = cookie;
  }

  // ✅ SEND JSON AS application/json PART (VERY IMPORTANT)
  request.files.add(
    http.MultipartFile.fromString(
      'data',
      jsonEncode(reportData),
      contentType: MediaType('application', 'json'),
    ),
  );

  // ✅ OPTIONAL IMAGE
  if (image != null && await image.exists()) {
    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );
  }

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200 || response.statusCode == 201) {
    return response.body;
  } else {
    throw Exception(
      'Save failed: ${response.statusCode} → ${response.body}',
    );
  }
}

  
}