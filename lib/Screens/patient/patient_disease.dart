import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:healthcare/models/disease_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PatientDisease extends StatefulWidget {
  const PatientDisease({super.key});

  @override
  State<PatientDisease> createState() => _PatientDiseaseState();
}

class _PatientDiseaseState extends State<PatientDisease> {
  List<Disease> diseases = [];
  List<int> selectedDiseases = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDiseases();
  }

  // ================= FETCH DISEASES =================
  Future<void> fetchDiseases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patient/diseases'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      debugPrint('FETCH Status: ${response.statusCode}');
      debugPrint('FETCH Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          diseases = data.map((e) => Disease.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load diseases');
      }
    } catch (e) {
      debugPrint('Error fetching diseases: $e');
      setState(() => isLoading = false);
    }
  }

  // ================= SELECT DISEASE =================
  void onSelectDisease(bool? checked, int diseaseId) {
    setState(() {
      if (checked == true) {
        if (!selectedDiseases.contains(diseaseId)) {
          selectedDiseases.add(diseaseId);
        }
      } else {
        selectedDiseases.remove(diseaseId);
      }
    });
  }

  // ================= SAVE DISEASES =================
  Future<void> submitDiseases() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString('activePatientId');
    final cookie = prefs.getString('session_cookie');

    if (patientId == null) {
      debugPrint('Patient ID is null');
      return;
    }

    if (selectedDiseases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one disease')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/patient/assign-diseases'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
        body: json.encode({
          'patientId': patientId,
          'diseaseIds': selectedDiseases,
        }),
      );

      debugPrint('SAVE Status: ${response.statusCode}');
      debugPrint('SAVE Body: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.body)),
        );

        Navigator.pushReplacementNamed(context, '/patient-dashboard');
      } else {
        throw Exception('Failed to save diseases');
      }
    } catch (e) {
      debugPrint('Error saving diseases: $e');
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Diseases')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: diseases.length,
                      itemBuilder: (context, index) {
                        final disease = diseases[index];
                        return Card(
                          elevation: 2,
                          margin:
                              const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedDiseases
                                      .contains(disease.id),
                                  onChanged: (checked) =>
                                      onSelectDisease(
                                          checked, disease.id),
                                ),
                                Expanded(
                                  child: Text(
                                    disease.diseaseName,
                                    style: const TextStyle(
                                        fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 20, top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitDiseases,
                        child: const Text('Save Diseases'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
