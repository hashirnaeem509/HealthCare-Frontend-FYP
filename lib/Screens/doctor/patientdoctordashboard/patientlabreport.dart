import 'package:flutter/material.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:healthcare/services/LabReportService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientdocrecommented.dart';
import 'package:fl_chart/fl_chart.dart';

class PatientLabReportsScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientLabReportsScreen({
    super.key,
    required this.patient,
    required String reportId,
    required String patientId,
  });

  @override
  State<PatientLabReportsScreen> createState() =>
      _PatientLabReportsScreenState();
}

class _PatientLabReportsScreenState extends State<PatientLabReportsScreen> {
  bool loading = true;
  String errorMsg = '';
  List<Map<String, dynamic>> reports = [];

  final LabReportService _service = LabReportService();

  // Graph state
  bool showGraph = false;
  String? selectedGraphField;
  List<String> graphFields = [];
  Map<String, List<Map<String, dynamic>>> groupedByField = {};
  List<Map<String, dynamic>> graphData = [];

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
          'value': r['value']?.toString() ?? '-',
          'date': r['date']?.toString() ?? '',
          'time': r['time']?.toString() ?? '',
          'isCritical': r['critical'] == true,
        });
      }

      // Sort dates and values descending
      for (var report in grouped.values) {
        (report['dates'] as List<Map<String, String>>).sort((a, b) {
          final dtA = DateTime.parse("${a['date']} ${a['time']}");
          final dtB = DateTime.parse("${b['date']} ${b['time']}");
          return dtB.compareTo(dtA);
        });

        for (var field in report['fields']) {
          (field['values'] as List<Map<String, dynamic>>).sort((a, b) {
            final dtA = DateTime.parse("${a['date']} ${a['time']}");
            final dtB = DateTime.parse("${b['date']} ${b['time']}");
            return dtB.compareTo(dtA);
          });
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

  void goToRecommend() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorIdStr = prefs.getString('doctorId');
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

    final reportsToSend = reports.expand((r) {
      return (r['dates'] as List).map((d) {
        return {
          'reportId': d['reportId'],
          'reportName': r['reportName'],
          'labName': r['labName'],
          'date': d['date'],
          'time': d['time'],
        };
      });
    }).toList();

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

  // Show graph inline
  void showGraphForReport(Map<String, dynamic> report) {
    final allFields = (report['fields'] as List)
        .map((f) => f['fieldName'].toString())
        .toList();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var f in report['fields']) {
      grouped[f['fieldName']] = (f['values'] as List<dynamic>)
          .map((v) => {
                'date': v['date'] ?? '',
                'value': double.tryParse(v['value']?.toString() ?? '') ?? 0.0,
                'isCritical': v['isCritical'] == true,
              })
          .toList();
    }

    setState(() {
      showGraph = true;
      graphFields = allFields;
      groupedByField = grouped;
      selectedGraphField = allFields.isNotEmpty ? allFields.first : null;
      graphData = grouped[selectedGraphField!]!;
    });
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
            onPressed: goToRecommend,
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
                                      // Use 10.0.2.2 if using Android emulator
                                      ApiConfig.resolveImageUrl(
                                          patient['profileImageUrl']),
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  )
                                : const DecorationImage(
                                    image:
                                        AssetImage('assets/images/download.png'),
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
                      final fields =
                          report['fields'] as List<Map<String, dynamic>>;
                      final dates = report['dates'] as List<Map<String, String>>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${report['reportName']} — ${report['labName']}",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        showGraphForReport(report),
                                    icon: const Icon(Icons.bar_chart),
                                    label: const Text("View Graph"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      Colors.blue.shade300),
                                  headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  columns: [
                                    const DataColumn(label: Text('Field Name')),
                                    ...dates.map((d) => DataColumn(
                                        label:
                                            Text("${d['date']}\n${d['time']}"))),
                                    const DataColumn(label: Text('Unit')),
                                  ],
                                  rows: fields.map<DataRow>((f) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(f['fieldName'] ?? '')),
                                        ...dates.map((d) {
                                          final val = getFieldValue(
                                              f, d['date']!, d['time']!);
                                          final isCritical = isCriticalValue(
                                              f, d['date']!, d['time']!);
                                          return DataCell(
                                            Text(
                                              val,
                                              style: TextStyle(
                                                color: isCritical
                                                    ? Colors.red
                                                    : Colors.black,
                                                fontWeight: isCritical
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
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
                    }).toList(),

                    // Inline Graph Display
                    if (showGraph && graphData.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Graph View",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text("Select Field: "),
                                const SizedBox(width: 10),
                                DropdownButton<String>(
                                  value: selectedGraphField,
                                  items: graphFields
                                      .map((f) => DropdownMenuItem(
                                          value: f, child: Text(f)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() {
                                      selectedGraphField = val;
                                      graphData = groupedByField[val]!;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: graphData.isNotEmpty
                                      ? graphData
                                              .map((v) => v['value'] as double)
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.2
                                      : 100.0,
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 ||
                                              index >= graphData.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Text(
                                              graphData[index]['date']);
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(
                                    graphData.length,
                                    (index) {
                                      final item = graphData[index];
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: item['value'] as double,
                                            width: 18,
                                            color: item['isCritical'] == true
                                                ? Colors.red
                                                : Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
