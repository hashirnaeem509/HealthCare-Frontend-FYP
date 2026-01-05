import 'package:flutter/material.dart';
import 'package:healthcare/services/LabReportService.dart';


class SingleLabReportScreen extends StatefulWidget {
  final String patientId;
  final String reportId;

  const SingleLabReportScreen({
    super.key,
    required this.patientId,
    required this.reportId,
  });

  @override
  State<SingleLabReportScreen> createState() => _SingleLabReportScreenState();
}

class _SingleLabReportScreenState extends State<SingleLabReportScreen> {
  final LabReportService labService = LabReportService();

  bool loading = true;
  Map<String, dynamic>? report;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

 Future<void> loadReport() async {
  debugPrint("📄 Loading lab report...");
  debugPrint("➡ patientId: ${widget.patientId}");
  debugPrint("➡ reportId: ${widget.reportId}");

  try {
    final allReports = await labService.getPatientReports(widget.patientId);

    debugPrint("✅ Lab report API success");
    debugPrint("📦 Response: $allReports");

    // Filter all fields for this report
    final reportFields = allReports
        .where((r) => r['reportId'].toString() == widget.reportId)
        .toList();

    if (reportFields.isEmpty) {
      debugPrint("❌ Report not found");
      setState(() => loading = false);
      return;
    }

    // Build a report object with parameters
    final reportObj = {
      'reportId': widget.reportId,
      'reportName': reportFields[0]['reportName'],
      'reportDate': reportFields[0]['date'],
      'reportTime': reportFields[0]['time'],
      'parameters': reportFields.map((f) => {
        'name': f['fieldName'],
        'value': f['value'],
        'unit': f['unit'],
        'minRange': f['minRange'] ?? 0, // optional
        'maxRange': f['maxRange'] ?? 9999, // optional
        'critical': f['critical'] ?? false,
      }).toList(),
    };

    setState(() {
      report = reportObj;
      loading = false;
    });
  } catch (e, stack) {
    debugPrint("❌ Lab report load FAILED");
    debugPrint("❌ Error: $e");
    debugPrint("📌 Stack: $stack");

    setState(() => loading = false);
  }
}

  bool isCritical(dynamic value, dynamic min, dynamic max) {
    final v = double.tryParse(value.toString());
    if (v == null) return false;
    return v < min || v > max;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lab Report")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? const Center(child: Text("No report found"))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Card(
                        child: ListTile(
                          title: Text(
                            report!['reportName'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${report!['reportDate']} ${report!['reportTime'] ?? ''}",
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// PARAMETERS
                      Expanded(
                        child: ListView.builder(
                          itemCount: report!['parameters'].length,
                          itemBuilder: (_, i) {
                            final p = report!['parameters'][i];
                            final critical = isCritical(
                              p['value'],
                              p['minRange'],
                              p['maxRange'],
                            );

                            return Card(
                              color: critical
                                  ? Colors.red.shade100
                                  : Colors.green.shade50,
                              child: ListTile(
                                title: Text(
                                  p['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        critical ? Colors.red : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  "Value: ${p['value']} ${p['unit']}\n"
                                  "Normal: ${p['minRange']} - ${p['maxRange']}",
                                ),
                                trailing: Icon(
                                  critical
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color: critical
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
