import 'package:flutter/material.dart';
import 'package:healthcare/services/LabReportService.dart';

class PatientLabReportsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientLabReportsScreen({super.key, required this.patient});

  @override
  State<PatientLabReportsScreen> createState() => _PatientLabReportsScreenState();
}

class _PatientLabReportsScreenState extends State<PatientLabReportsScreen> {
  bool loading = true;
  String errorMsg = '';
  List<Map<String, dynamic>> reports = [];

  final LabReportService _service = LabReportService();

  @override
  void initState() {
    super.initState();
    loadLabReports();
  }

  /// Fetch reports like Angular getPatientReports() approach
  Future<void> loadLabReports() async {
    setState(() {
      loading = true;
      errorMsg = '';
    });

    try {
    final data = await _service.getPatientReports(widget.patient['id'].toString());


      // Group by reportName + labName
      Map<String, Map<String, dynamic>> grouped = {};
      for (var r in data) {
  String labName = r['labName'] ?? '';
  String key = "${r['reportName']}-$labName";

  if (!grouped.containsKey(key)) {
    grouped[key] = {
      "reportName": r['reportName'],
      "labName": labName,
      "fields": [],
    };
  }

  grouped[key]!['fields'].add({
    "fieldName": r['fieldName'],
    "value": r['value'],
    "unit": r['unit'],
    "date": r['date'],
    "time": r['time'],
  });
}


      setState(() {
        reports = grouped.values
            .map((r) => {
                  "reportName": r['reportName'],
                  "labName": r['labName'],
                  "fields": [...r['fields']],
                })
            .toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = 'Failed to load lab reports: $e';
      });
    }
  }

  void goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text("${patient['fullName']} Lab Reports"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: goBack),
        backgroundColor: Colors.lightBlue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // Patient Info Header
                    Row(
                      children: [
                         Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          image: const DecorationImage(
            image: AssetImage('assets/images/download.png'),
            fit: BoxFit.cover,
          ),
        ),
            ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(patient['fullName'] ?? 'Patient',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("DOB: ${patient['dob'] ?? 'N/A'}"),
                            Text("Gender: ${patient['gender'] ?? 'N/A'}"),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Lab Reports
                    ...reports.map((report) {
                      final fields = report['fields'] as List<dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${report['reportName']} — ${report['labName']}",
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                             SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: DataTable(
    headingRowColor: MaterialStateProperty.all(Colors.blue.shade300), // Header background
    headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Header text color
    columns: const [
      DataColumn(label: Text('Field Name')),
      DataColumn(label: Text('Value')),
      DataColumn(label: Text('Unit')),
      DataColumn(label: Text('Date')),
      DataColumn(label: Text('Time')),
    ],
    rows: fields.map<DataRow>((f) => DataRow(
      cells: [
        DataCell(Text(f['fieldName'] ?? '')),
        DataCell(Text(f['value']?.toString() ?? '')),
        DataCell(Text(f['unit'] ?? '')),
        DataCell(Text(f['date'] ?? '')),
        DataCell(Text(f['time'] ?? '')),
      ],
    )).toList(),
  ),
),

                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

}
