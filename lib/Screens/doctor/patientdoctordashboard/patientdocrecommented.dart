import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/services/recommendation.dart';

/// Model representing a simple report
class SimpleReport {
  final int reportId;
  final String reportName;
  final String labName;
  final String date;
  final String time;
  bool selected;

  SimpleReport({
    required this.reportId,
    required this.reportName,
    required this.labName,
    required this.date,
    required this.time,
    this.selected = false,
  });
}

class DoctorRecommendScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final List<dynamic> reports;

  const DoctorRecommendScreen({
    super.key,
    required this.patient,
    required this.reports,
  });

  @override
  State<DoctorRecommendScreen> createState() => _DoctorRecommendScreenState();
}

class _DoctorRecommendScreenState extends State<DoctorRecommendScreen> {
  late int patientId;
  late String patientName;

  List<SimpleReport> reportList = [];
  bool loading = true;
  String message = '';
  int? doctorId;

  final RecommendService _recommendService = RecommendService();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
    _loadDoctorId();
  }

  /// Load initial data from passed parameters
  void loadData() {
    patientId = widget.patient['id'] ?? 0;
    patientName = widget.patient['fullName'] ?? 'Unknown';

    print('🟢 loadData: patientId=$patientId, patientName=$patientName');

    reportList = widget.reports.map((r) {
      final reportId = r['reportId'];
      final reportName = r['reportName'] ?? 'Unknown Report';
      final labName = r['labName'] ?? 'Unknown Lab';
      final date = r['date'] ?? '';
      final time = r['time'] ?? '';

      print('🟢 loadData: raw reportId=$reportId');

      return SimpleReport(
        reportId: reportId is int ? reportId : int.tryParse(reportId.toString()) ?? 0,
        reportName: reportName,
        labName: labName,
        date: date,
        time: time,
      );
    }).toList();

    for (var r in reportList) {
      print('🟢 loadData: loaded report ${r.reportId} - ${r.reportName}');
    }

    setState(() => loading = false);
  }

  /// Safely load doctorId from SharedPreferences (string -> int)
 Future<void> _loadDoctorId() async {
  final prefs = await SharedPreferences.getInstance();

  // Always get as string
  final doctorIdStr = prefs.getString('doctorId');
  print('🔹 SharedPreferences doctorIdStr: $doctorIdStr');

  if (doctorIdStr == null || doctorIdStr.isEmpty) {
    // Cannot show SnackBar directly in async initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor not logged in')),
      );
      Navigator.pop(context);
    });
    return;
  }

  // Parse string to int safely
  final parsedId = int.tryParse(doctorIdStr);
  if (parsedId == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid doctor ID')),
      );
      Navigator.pop(context);
    });
    return;
  }

  setState(() => doctorId = parsedId);
  print('🟢 _loadDoctorId: doctorId=$doctorId');
}




  /// Submit recommendation
  Future<void> submitRecommendation() async {
    final selectedReports = reportList.where((r) => r.selected).toList();
    print('🟢 submitRecommendation: selectedReports=${selectedReports.map((r) => r.reportId).toList()}');

    if (selectedReports.isEmpty) {
      showMsg('Select at least one report');
      print('🔴 submitRecommendation: no reports selected');
      return;
    }

    if (doctorId == null) {
      showMsg('Doctor not logged in');
      print('🔴 submitRecommendation: doctorId is null');
      return;
    }

    final reportIds = selectedReports.map((r) => r.reportId).toList();
    print('🟢 submitRecommendation: sending request patientId=$patientId, reportIds=$reportIds, doctorId=$doctorId, message="$message"');

    try {
      await _recommendService.recommendReports(
        patientId,
        reportIds,
        message,
        doctorId!,
      );

      showMsg('Recommendation sent successfully');
      print('✅ submitRecommendation: recommendation sent successfully');
      Navigator.pop(context);
    } catch (e) {
      showMsg('Failed to send recommendation');
      print('❌ submitRecommendation: error sending recommendation: $e');
    }
  }

  /// Helper to show snack bar messages
  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommend Reports'),
        backgroundColor: Colors.lightBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: goBack,
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommend Reports for $patientName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table of reports
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Select')),
                          DataColumn(label: Text('Report Name')),
                          DataColumn(label: Text('Lab Name')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Time')),
                        ],
                        rows: reportList.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: r.selected,
                                  onChanged: (val) {
                                    setState(() {
                                      r.selected = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              DataCell(Text(r.reportName)),
                              DataCell(Text(r.labName)),
                              DataCell(Text(r.date)),
                              DataCell(Text(r.time)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message / Notes input
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Message / Notes',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => message = v,
                  ),
                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: submitRecommendation,
                        child: const Text('Send Recommendation'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: goBack,
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
