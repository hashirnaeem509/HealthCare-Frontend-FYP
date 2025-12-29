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
// Track which fields are critical
final Map<int, bool> _criticalFields = {};


  List<dynamic> tests = [];
  List<dynamic> fields = [];
  int? selectedTestId;

  bool isLoadingTests = false;
  bool isLoadingFields = false;

  // Controllers for fields
  final Map<int, TextEditingController> _controllers = {};
  

  @override
  void initState() {
    super.initState();
    loadTests();
  }

Future<void> checkFieldCritical(int fieldId, String value) async {
  final prefs = await SharedPreferences.getInstance();
  final storedId = prefs.get('activePatientId');
  if (storedId == null) return;

  final patientId = int.tryParse(storedId.toString());
  if (patientId == null) return;

  // Extract first numeric value from input
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(value.replaceAll(',', ''));
  if (match == null) {
    setState(() => _criticalFields[fieldId] = false);
    return;
  }

  final doubleValue = double.tryParse(match.group(0)!);
  if (doubleValue == null) {
    setState(() => _criticalFields[fieldId] = false);
    return;
  }

  try {
    final isCritical = await _service.checkCritical(
      patientId: patientId,
      fieldId: fieldId,
      value: doubleValue,
    );
    setState(() => _criticalFields[fieldId] = isCritical);
    debugPrint("FIELD=$fieldId VALUE=$doubleValue CRITICAL=$isCritical");
  } catch (e) {
    debugPrint("Error checking critical: $e");
  }
}


  /// Load all lab tests
  Future<void> loadTests() async {
    setState(() => isLoadingTests = true);
    try {
      tests = await _service.getLabTests();
      debugPrint("Loaded ${tests.length} lab tests");
    } catch (e) {
      debugPrint("Error loading tests: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error loading tests: $e"),
      ));
    } finally {
      setState(() => isLoadingTests = false);
    }
  }

  /// Load fields for selected test
  Future<void> loadFieldsForSelectedTest() async {
    if (selectedTestId == null) return;

    setState(() {
      isLoadingFields = true;
      fields = [];
    });

    try {
      final fetchedFields = await _service.getFieldsByTest(selectedTestId!);
      fields = fetchedFields.map((f) {
        return {
          ...f,
          "value": "",
          "fullRows": <String>[],
          "values": <String>[],
        };
      }).toList();

      debugPrint("Loaded ${fields.length} fields for testId $selectedTestId");
    } catch (e) {
      debugPrint("Error loading fields: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error loading fields: $e"),
      ));
    } finally {
      setState(() => isLoadingFields = false);
    }
  }

  /// Open scan screen and populate OCR data into fields
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

    if (extractedData != null) {
      debugPrint("OCR data received: $extractedData");

      // Convert to Map<String, dynamic>
      final Map<String, dynamic> ocrMap = {};
      (extractedData as Map).forEach((k, v) {
        ocrMap[k.toString()] = v;
      });

      // Populate fields with OCR data
      for (var field in fields) {
        final fieldName = field['fieldName'];
        if (fieldName == null) continue;

        // Find matching OCR entries
        final matchingEntries = ocrMap.entries.where(
          (e) => e.key.toLowerCase().contains(fieldName.toLowerCase()),
        ).toList();

        final lines = <String>[];
        for (var entry in matchingEntries) {
          final entryText = entry.value?.toString() ?? '';
          lines.addAll(entryText.split('\n'));
        }

        field['fullRows'] = lines;

        // Extract numeric values (optional, can be removed if not needed)
        final allValues = <String>[];
        for (var line in lines) {
          final matches = RegExp(r'(\d+(?:,\d+)?(?:\.\d+)?)').allMatches(line);
          for (var m in matches) {
            allValues.add(m.group(0)!.replaceAll(',', ''));
          }
        }

        field['values'] = allValues;
       field['value'] = allValues.isNotEmpty ? allValues.first : null;

// Initialize controller
_controllers[field['fieldId']] = TextEditingController(text: lines.join('\n'));

// ✅ Immediately check if OCR value is critical
if (field['value'] != null) {
  checkFieldCritical(field['fieldId'], field['value'].toString());
}
else {
          _controllers[field['fieldId']]!.text = lines.join('\n');
        }

        debugPrint("Field '$fieldName' -> Lines: ${lines.length}, Values: $allValues");
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All extracted data loaded successfully!")),
      );
    }
  }

  /// Save manual report
 Future<void> saveManualReport() async {
  if (selectedTestId == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Select a test first!")));
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final dynamic storedId = prefs.get('activePatientId');
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
    "fieldValues": fields.where((f) => f["fieldId"] != null).map((f) {
      return {
        "fieldId": f["fieldId"],
        "value": f["value"],
        "unit": f["unit"] ?? "",
      };
    }).toList(),
  };

  debugPrint("FINAL PAYLOAD =====> $payload");

  try {
    // ✅ Use the multipart method (no file for now)
 final response = await _service.saveManualReportWithImage(payload, null);
    debugPrint("Saved Response: $response");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report saved successfully!")),
    );

    // Clear state
    setState(() {
      selectedTestId = null;
      fields.clear();
      _controllers.clear();
    });
  } catch (e) {
    debugPrint("Failed to save report: $e");
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Failed to save: $e")));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lab Report")),
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
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
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
  controller: _controllers[field['fieldId']],
  maxLines: null,
  decoration: InputDecoration(
    border: OutlineInputBorder(),
    labelText: field['fieldName'],
    filled: true,
    fillColor: _criticalFields[field['fieldId']] == true 
        ? Colors.red.withOpacity(0.2) 
        : Colors.white,
  ),
  style: TextStyle(
    color: _criticalFields[field['fieldId']] == true ? Colors.red : Colors.black,
    fontWeight: _criticalFields[field['fieldId']] == true ? FontWeight.bold : FontWeight.normal,
  ),
  onChanged: (val) {
    field['fullRows'] = val.split('\n');
    field['value'] = val;
    checkFieldCritical(field['fieldId'], val);
    setState(() {});
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
                                builder: (context) => const Patientdashborad(),
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
