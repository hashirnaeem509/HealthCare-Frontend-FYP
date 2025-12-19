import 'package:flutter/material.dart';
import 'package:healthcare/services/LabReportService.dart';
import 'package:healthcare/Screens/patient/ScanReport.dart';
import 'package:healthcare/Screens/patient/patientdashborad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabReport extends StatefulWidget {
  const LabReport({super.key});

  @override
  State<LabReport> createState() => _LabReportScreenState();
}

class _LabReportScreenState extends State<LabReport> {
  final LabReportService _service = LabReportService();

  List<dynamic> tests = [];
  List<dynamic> fields = [];
  int? selectedTestId;

  bool isLoadingTests = false;
  bool isLoadingFields = false;

  @override
  void initState() {
    super.initState();
    loadTests();
  }

  Future<void> loadTests() async {
    setState(() => isLoadingTests = true);
    try {
      tests = await _service.getLabTests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading tests: $e")),
      );
    } finally {
      setState(() => isLoadingTests = false);
    }
  }

  Future<void> loadFieldsForSelectedTest() async {
    if (selectedTestId == null) return;

    setState(() {
      isLoadingFields = true;
      fields = [];
    });

    try {
      fields = await _service.getFieldsByTest(selectedTestId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading fields: $e")),
      );
    } finally {
      setState(() => isLoadingFields = false);
    }
  }


  Future<void> goToScanScreen() async {
    if (selectedTestId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a test first!")));
      return;
    }

    final extractedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanReportScreen(labTestId: selectedTestId!),
      ),
    );

    if (extractedData != null && extractedData is Map<String, dynamic>) {
      setState(() {
        for (var field in fields) {
          final fieldName = field["fieldName"];
          if (extractedData.containsKey(fieldName)) {
            field["value"] = extractedData[fieldName].toString();
          }
        }

        extractedData.forEach((key, value) {
          final exists = fields.any((f) => f["fieldName"] == key);
          if (!exists) {
            fields.add({
              "fieldName": key,
              "value": value.toString(),
              "fieldId": null,
              "unit": ""
            });
          }
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Extracted data loaded successfully!")),
      );
    }
  }

 
  Future<void> saveManualReport() async {
    if (selectedTestId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a test first!")));
      return;
    }

    
    final prefs = await SharedPreferences.getInstance();
    final dynamic storedId = prefs.get('activePatientId');  //active
    final patientId = storedId?.toString();           

    final now = DateTime.now();
    final date = now.toIso8601String().split('T')[0];
    final time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final payload = {
      "patientId": patientId,
      "labTestId": selectedTestId,
      "reportName": tests.firstWhere(
        (t) => t["labTestId"] == selectedTestId,
        orElse: () => {"testName": "Manual Report"},
      )["testName"],
      "date": date,
      "time": time,
      "fieldValues": fields
          .where((f) => f["fieldId"] != null)
          .map((f) {
        return {
          "fieldId": f["fieldId"],
          "value": f["value"],
          "unit": f["unit"] ?? "",
        };
      }).toList(),
    };

    print("FINAL PAYLOAD =====> $payload");

    try {
      final response = await _service.saveManualReport(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report saved successfully!")),
      );

      print("Saved Response: $response");

      setState(() {
        selectedTestId = null;
        fields.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" Lab Report")),
      body: isLoadingTests
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: goToScanScreen,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.blue,
                            size: 60,
                          ),
                        ),
                        const Text(
                          "Tap camera to scan or upload your report",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Select Test",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTestId,
                    items: tests.map<DropdownMenuItem<int>>((test) {
                      return DropdownMenuItem<int>(
                        value: test["labTestId"],
                        child: Text(test["testName"]),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      setState(() => selectedTestId = val);
                      await loadFieldsForSelectedTest();
                    },
                  ),
                  const SizedBox(height: 20),
                  if (isLoadingFields)
                    const Center(child: CircularProgressIndicator())
                  else if (fields.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: fields.length,
                        itemBuilder: (context, index) {
                          final field = fields[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field["fieldName"] ?? "Unknown Field",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: field["value"] ?? "",
                                    decoration: InputDecoration(
                                      hintText: "Enter value",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      field["value"] = val;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text(
                      "Select a test to load its fields.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const Patientdashborad(),
                              ),
                            );
                          },
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: saveManualReport,
                          child: const Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
