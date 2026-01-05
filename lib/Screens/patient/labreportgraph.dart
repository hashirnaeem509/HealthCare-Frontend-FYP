import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:healthcare/services/LabReportService.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LabTrendPage extends StatefulWidget {
  final int labTestId;
  final String labTestName;

  const LabTrendPage({
    super.key,
    required this.labTestId,
    required this.labTestName,
  });

  @override
  State<LabTrendPage> createState() => _LabTrendPageState();
}

class _LabTrendPageState extends State<LabTrendPage> {
  String patientName = '';
  String? patientImage;

  List<dynamic> allReports = [];
  List<String> fields = [];
  String? selectedField;

  Map<String, List<Map<String, dynamic>>> groupedByField = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPatientInfo();
    loadReports();
  }

  /// Load patient info
  Future<void> loadPatientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('activePatientId');
    if (storedId == null) return;

    final patientId = int.tryParse(storedId);
    if (patientId == null) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patient/$patientId'),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          patientName = data['fullName'] ?? 'Patient';
          patientImage = data['profileImageUrl'];
        });
      }
    } catch (_) {
      setState(() {
        patientName = 'Patient';
        patientImage = null;
      });
    }
  }

  /// Load reports for the lab test
  Future<void> loadReports() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString('activePatientId');
    if (patientId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final reports = await LabReportService().getPatientReports(patientId);

      final filtered = reports
          .where((r) => r['reportName'] == widget.labTestName)
          .toList();

      final uniqueFields =
          filtered.map((r) => r['fieldName'] as String).toSet().toList();

      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var field in uniqueFields) {
        final fieldReports = filtered
            .where((r) => r['fieldName'] == field)
            .map((r) => {
                  'date': r['date'],
                  'value': (r['value'] as num).toDouble(),
                  // ✅ CRITICAL FLAG ADDED
                  'isCritical': r['critical'] == true || r['isCritical'] == true,
                })
            .toList();

        fieldReports.sort((a, b) =>
            DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

        grouped[field] = fieldReports;
      }

      setState(() {
        allReports = reports;
        fields = uniqueFields;
        groupedByField = grouped;
        selectedField = fields.isNotEmpty ? fields.first : null;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load reports: $e");
      setState(() => isLoading = false);
    }
  }

  /// Show dialog for value info
  void showValueDialog(String fieldName, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(fieldName),
        content: Text(
          "Date: ${report['date']}\nValue: ${report['value']}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataForField =
        selectedField != null ? groupedByField[selectedField!] ?? [] : [];

    final maxY = dataForField.isNotEmpty
        ? (dataForField
                .map((v) => v['value'] as double)
                .reduce((a, b) => a > b ? a : b) *
            1.2)
        : 7000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Test Trend'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage: patientImage != null
                              ? NetworkImage(patientImage!)
                              : const AssetImage('assets/icons/patient.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text("${widget.labTestName} Trend"),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Field selection dropdown
                    if (fields.isNotEmpty)
                      Row(
                        children: [
                          const Text('Select Field: '),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedField,
                            items: fields
                                .map((f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedField = val;
                              });
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),

                    // Chart
                    SizedBox(
                      height: 300,
                      child: dataForField.isEmpty
                          ? const Center(
                              child: Text(
                                'No data available for this test.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY,

                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchCallback: (event, response) {
                                    if (response == null ||
                                        response.spot == null) return;

                                    if (event is FlTapUpEvent) {
                                      final index = response
                                          .spot!.touchedBarGroupIndex;
                                      final report = dataForField[index];

                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!mounted) return;
                                        showValueDialog(
                                            selectedField!, report);
                                      });
                                    }
                                  },
                                ),

                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1000,
                                      reservedSize: 45,
                                     getTitlesWidget: (value, meta) {
  // If value is 1000 or more, show in 'K'
  if (value >= 1000) {
    return Text(
      "${(value / 1000).toInt()}K",
      style: const TextStyle(fontSize: 12),
    );
  } else {
    // If value is less than 1000, show normally without 'K'
    return Text(
      "${value.toInt()}",
      style: const TextStyle(fontSize: 12),
    );
  }
},

                                      
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= dataForField.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            dataForField[index]['date'],
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false),
                                  ),
                                ),

                                borderData:
                                    FlBorderData(show: false),

                                // ✅ CRITICAL COLOR LOGIC HERE
                                barGroups: List.generate(
                                  dataForField.length,
                                  (index) {
                                    final item = dataForField[index];
                                    final double val = item['value'];
                                    final bool isCritical =
                                        item['isCritical'] == true;

                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: val,
                                          width: 18,
                                          color: isCritical
                                              ? Colors.red
                                              : Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          borderSide: isCritical
                                              ? const BorderSide(
                                                  color: Colors.redAccent,
                                                  width: 2,
                                                )
                                              : BorderSide.none,
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
            ),
    );
  }
}
