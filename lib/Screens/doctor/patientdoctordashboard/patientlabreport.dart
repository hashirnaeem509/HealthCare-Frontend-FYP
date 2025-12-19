import 'package:flutter/material.dart';
import 'package:healthcare/services/LabReportService.dart';

class PatientLabReportsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientLabReportsScreen({super.key, required this.patient});

  @override
  State<PatientLabReportsScreen> createState() =>
      _PatientLabReportsScreenState();
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

 
  Future<void> loadLabReports() async {
    setState(() {
      loading = true;
      errorMsg = '';
    });

    try {
      final data = await _service.getPatientReports(
        widget.patient['id']?.toString() ?? '',
      );


      Map<String, Map<String, dynamic>> grouped = {};

      for (var r in data) {
        String labName = r['labName']?.toString() ?? '';
        String reportName = r['reportName']?.toString() ?? '';
        String reportKey = "$reportName-$labName";

        if (!grouped.containsKey(reportKey)) {
          grouped[reportKey] = {
            "reportName": reportName,
            "labName": labName,
            "fields": <Map<String, dynamic>>[],
            "dates": <Map<String, String>>[],
          };
        }

        final report = grouped[reportKey]!;

        
        final dateTime = {
          'date': r['date']?.toString() ?? '',
          'time': r['time']?.toString() ?? ''
        };
        if (!report['dates'].any((d) =>
            d['date'] == dateTime['date'] && d['time'] == dateTime['time'])) {
          report['dates'].add(dateTime);
        }

      
        final fieldName = r['fieldName']?.toString() ?? '';
        var field = report['fields'].firstWhere(
          (f) => f['fieldName'] == fieldName,
          orElse: () {
            final newField = {
              'fieldName': fieldName,
              'unit': r['unit']?.toString() ?? '',
              'values': <Map<String, String>>[],
            };
            report['fields'].add(newField);
            return newField;
          },
        );

        
        field['values'].add({
          'value': r['value']?.toString() ?? '',
          'date': r['date']?.toString() ?? '',
          'time': r['time']?.toString() ?? '',
        });
      }

      setState(() {
        reports = grouped.values.toList();
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

  String getFieldValue(Map<String, dynamic> field, String date, String time) {
    final values = field['values'] as List<Map<String, String>>;
    final val = values.firstWhere(
      (v) => v['date'] == date && v['time'] == time,
      orElse: () => {'value': '-'},
    );
    return val['value'] ?? '-';
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
              ? Center(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
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
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("DOB: ${patient['dob'] ?? 'N/A'}"),
                            Text("Gender: ${patient['gender'] ?? 'N/A'}"),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Lab Reports
                    ...reports.map((report) {
                      final fields = report['fields'] as List<Map<String, dynamic>>;
                      final dates = report['dates'] as List<Map<String, String>>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${report['reportName']} — ${report['labName']}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.blue.shade300),
                                  headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  columns: [
                                    const DataColumn(label: Text('Field Name')),
                                    ...dates.map((d) => DataColumn(
                                        label: Text("${d['date']}\n${d['time']}"))),
                                    const DataColumn(label: Text('Unit')),
                                  ],
                                  rows: fields.map<DataRow>((f) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(f['fieldName'] ?? '')),
                                        ...dates.map((d) => DataCell(
                                            Text(getFieldValue(f, d['date']!, d['time']!)))),
                                        DataCell(Text(f['unit'] ?? '')),
                                      ],
                                    );
                                  }).toList(),
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
