import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/LabReportService.dart';

class ExtractedDataScreen extends StatefulWidget {
  final int labTestId;
  final Map<String, dynamic> ocrData;

  const ExtractedDataScreen({
    super.key,
    required this.labTestId,
    required this.ocrData,
  });

  @override
  State<ExtractedDataScreen> createState() => _ExtractedDataScreenState();
}

class _ExtractedDataScreenState extends State<ExtractedDataScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final LabReportService _service = LabReportService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadManualAndOCRData();
  }

  /// 🧩 Load manual DB fields + merge OCR data
  Future<void> _loadManualAndOCRData() async {
    try {
      final manualFields = await _service.getFieldsByTest(widget.labTestId);
      final manualFieldsSet = <String>{};

      // 🔹 Step 1: Add manual fields + merge OCR data
      for (var field in manualFields) {
        final fieldName = field['fieldName']?.toString().trim();
        if (fieldName == null || fieldName.isEmpty) continue;

        manualFieldsSet.add(fieldName);

        final valueFromOCR = widget.ocrData[fieldName]?.toString().trim() ?? '';
        _controllers[fieldName] = TextEditingController(text: valueFromOCR);
      }

      // 🔹 Step 2: Add remaining OCR fields that are not in manualFields
      widget.ocrData.forEach((key, value) {
        final fieldName = key.toString().trim();
        final fieldValue = value?.toString().trim() ?? '';
        if (fieldName.isEmpty || fieldValue.isEmpty) return;
        if (!manualFieldsSet.contains(fieldName)) {
          _controllers[fieldName] = TextEditingController(text: fieldValue);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading fields: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 💾 Save data to backend
  Future<void> _saveData() async {
    final Map<String, dynamic> updatedData = {};
    _controllers.forEach((key, controller) {
      updatedData[key] = controller.text;
    });


    final payload = {
      "labId": widget.labTestId,
      "labTest": {"labTestId": widget.labTestId},
      "fields": updatedData,
    };

    try {
      await _service.saveManualReport(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Data saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save: $e")),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Extracted Lab Data")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: _controllers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: TextFormField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: entry.key,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveData,
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                  )
                ],
              ),
            ),
    );
  }
}
