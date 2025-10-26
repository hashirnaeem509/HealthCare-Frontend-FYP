import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/LabReportService.dart';
import 'package:healthcare/Screens/ui/ScanReport.dart';

class LabReport extends StatefulWidget {
  const LabReport({super.key});

  @override
  State<LabReport> createState() => _LabReportScreenState();
}

class _LabReportScreenState extends State<LabReport> {
  final LabReportService _service = LabReportService();
  List<dynamic> tests = [];
  int? selectedTestId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTests();
  }

  Future<void> loadTests() async {
    setState(() => isLoading = true);
    try {
      tests = await _service.getLabTests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading tests: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void goToScanScreen() {
    if (selectedTestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a test first!")),
      );
      return;
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanReportScreen(labTestId: selectedTestId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lab Report")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Select Test",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTestId,
                    items: (tests.isNotEmpty
                            ? tests
                                .map<DropdownMenuItem<int>>((test) {
                                  final id = test["labTestId"] ?? 0;
                                  final name = test["testName"] ?? "Unknown Test";
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text(name),
                                  );
                                })
                                .toList()
                            : <DropdownMenuItem<int>>[]),
                    onChanged: (val) => setState(() => selectedTestId = val),
                  ),
                  const SizedBox(height: 30),
                  IconButton(
                    onPressed: goToScanScreen,
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.blue, size: 60),
                  ),
                  const Text("Tap camera to scan or upload your report"),
                ],
              ),
            ),
    );
  }
}
