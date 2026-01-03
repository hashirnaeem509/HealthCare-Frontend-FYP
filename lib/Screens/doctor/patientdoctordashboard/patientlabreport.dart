import 'package:flutter/material.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientdocrecommented.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:healthcare/services/LabReportService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientLabReportsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientLabReportsScreen({super.key, required this.patient, required String reportId, required String patientId});

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
          'time': r['time']?.toString() ?? '',
          'reportId': r['reportId']?.toString() ?? '',
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
              'values': <Map<String, dynamic>>[],
            };
            report['fields'].add(newField);
            return newField;
          },
        );

        field['values'].add(<String, dynamic>{
          'value': r['value']?.toString() ?? '',
          'date': r['date']?.toString() ?? '',
          'time': r['time']?.toString() ?? '',
          'isCritical': r['critical'] == true,
        });


        for (var report in grouped.values) {
      (report['dates'] as List<Map<String, String>>).sort((a, b) {
        final dtA = DateTime.parse("${a['date']} ${a['time']}");
        final dtB = DateTime.parse("${b['date']} ${b['time']}");
        return dtB.compareTo(dtA); // DESCENDING order
      });

      // Also sort field values according to date/time
      for (var field in report['fields']) {
        (field['values'] as List<Map<String, dynamic>>).sort((a, b) {
          final dtA = DateTime.parse("${a['date']} ${a['time']}");
          final dtB = DateTime.parse("${b['date']} ${b['time']}");
          return dtB.compareTo(dtA);
        });
      }
    }
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
  
 /// ✅ Angular-style navigation with doctorId log
void goToRecommend() async {
  // 1️⃣ Read doctorId from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final doctorIdStr = prefs.getString('doctorId');
  print('🔹 goToRecommend: doctorIdStr from SharedPreferences: $doctorIdStr');

  if (doctorIdStr == null || doctorIdStr.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor not logged in')),
    );
    return;
  }

  final doctorId = int.tryParse(doctorIdStr);
  if (doctorId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid doctor ID')),
    );
    return;
  }
  print('🟢 goToRecommend: doctorId parsed as int: $doctorId');

  // 2️⃣ Prepare reports to send
  final reportsToSend = reports.expand((r) {
    return (r['dates'] as List).map((d) {
      final reportId = d['reportId'];
      if (reportId == null) {
        print('🔴 Warning: reportId is null for report ${r['reportName']}');
      }
      return {
        'reportId': reportId,
        'reportName': r['reportName'],
        'labName': r['labName'],
        'date': d['date'],
        'time': d['time'],
      };
    });
  }).toList();

  print('🟢 goToRecommend: Sending ${reportsToSend.length} reports to DoctorRecommendScreen');

  // 3️⃣ Navigate to DoctorRecommendScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DoctorRecommendScreen(
        patient: {
          'id': widget.patient['id'],
          'fullName': widget.patient['fullName'],
        },
        reports: reportsToSend,
      ),
    ),
  );
}



  

  String getFieldValue(Map<String, dynamic> field, String date, String time) {
    final values = (field['values'] as List<dynamic>).cast<Map<String, dynamic>>();
    final val = values.firstWhere(
      (v) => v['date'] == date && v['time'] == time,
      orElse: () => {'value': '-', 'isCritical': false},
    );
    return val['value']?.toString() ?? '-';
  }

  bool isCriticalValue(Map<String, dynamic> field, String date, String time) {
    final values = (field['values'] as List<dynamic>).cast<Map<String, dynamic>>();
    final val = values.firstWhere(
      (v) => v['date'] == date && v['time'] == time,
      orElse: () => {'isCritical': false},
    );
    return val['isCritical'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
  title: Text("${patient['fullName']} Lab Reports"),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: goBack,
  ),
  backgroundColor: Colors.lightBlue,
 actions: [
          TextButton.icon(
            onPressed: goToRecommend, // ✅ FIXED
            icon: const Icon(Icons.recommend, color: Colors.white),
            label: const Text(
              "Recommended",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
    shape: BoxShape.circle,
    image: patient['profileImageUrl'] != null &&
            patient['profileImageUrl'].toString().isNotEmpty
        ? DecorationImage(
            image: NetworkImage(
              ApiConfig.resolveImageUrl(patient['profileImageUrl']),
            ),
            fit: BoxFit.cover,
          )
        : const DecorationImage(
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
                                        ...dates.map((d) {
                                          final val = getFieldValue(f, d['date']!, d['time']!);
                                          final isCritical = isCriticalValue(f, d['date']!, d['time']!);
                                          return DataCell(
                                            Text(
                                              val,
                                              style: TextStyle(
                                                color: isCritical ? Colors.red : Colors.black,
                                                fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          );
                                        }),
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
