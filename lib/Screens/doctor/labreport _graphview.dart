// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:healthcare/config_/api_config.dart';
// import 'package:healthcare/services/LabReportService.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class LabReportGraphView extends StatefulWidget {
//   final int labTestId;
//   final String labTestName;

//   const LabReportGraphView({
//     super.key,
//     required this.labTestId,
//     required this.labTestName,
//   });

//   @override
//   State<LabReportGraphView> createState() => _LabReportGraphViewState();
// }

// class _LabReportGraphViewState extends State<LabReportGraphView> {
//   String patientName = '';
//   String? patientImage;

//   List<String> fields = [];
//   String? selectedField;

//   Map<String, List<Map<String, dynamic>>> groupedByField = {};
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadPatientInfo();
//     loadReports();
//   }

//   /// Load patient info
//   Future<void> loadPatientInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     final patientId = prefs.getString('activePatientId');
//     if (patientId == null) return;

//     try {
//       final res = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/patient/$patientId'),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         setState(() {
//           patientName = data['fullName'] ?? 'Patient';
//           patientImage = data['profileImageUrl'];
//         });
//       }
//     } catch (_) {
//       setState(() {
//         patientName = 'Patient';
//         patientImage = null;
//       });
//     }
//   }

//   /// Load lab reports filtered by labTestName
//   Future<void> loadReports() async {
//     setState(() => isLoading = true);

//     final prefs = await SharedPreferences.getInstance();
//     final patientId = prefs.getString('activePatientId');
//     if (patientId == null) return;

//     final reports = await LabReportService().getPatientReports(patientId);

//     // Filter by labTestName
//     final filtered =
//         reports.where((r) => r['reportName'] == widget.labTestName).toList();

//     final uniqueFields =
//         filtered.map((r) => r['fieldName'] as String).toSet().toList();

//     Map<String, List<Map<String, dynamic>>> grouped = {};

//     for (var field in uniqueFields) {
//       final fieldReports = filtered
//           .where((r) => r['fieldName'] == field)
//           .map((r) => {
//                 'date': r['date'],
//                 'value': (r['value'] as num).toDouble(),
//                 'isCritical': r['critical'] == true || r['isCritical'] == true,
//               })
//           .toList();

//       // Sort ascending by date
//       fieldReports.sort((a, b) =>
//           DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

//       grouped[field] = fieldReports;
//     }

//     setState(() {
//       fields = uniqueFields;
//       groupedByField = grouped;
//       selectedField = fields.isNotEmpty ? fields.first : null;
//       isLoading = false;
//     });
//   }

//   /// Show value dialog
//   void showValueDialog(Map<String, dynamic> report) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(selectedField ?? ''),
//         content: Text(
//           "Date: ${report['date']}\nValue: ${report['value']}",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Close"),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data =
//         selectedField != null ? groupedByField[selectedField!] ?? [] : [];

//     final maxY = data.isNotEmpty
//         ? (data.map((v) => v['value'] as double).reduce((a, b) => a > b ? a : b) *
//             1.2)
//         : 100.0;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.labTestName),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   /// Patient Header
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 35,
//                         backgroundImage: patientImage != null
//                             ? NetworkImage(ApiConfig.resolveImageUrl(patientImage!))
//                             : const AssetImage('assets/icons/patient.png')
//                                 as ImageProvider,
//                       ),
//                       const SizedBox(width: 16),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             patientName,
//                             style: const TextStyle(
//                                 fontSize: 20, fontWeight: FontWeight.bold),
//                           ),
//                           Text("${widget.labTestName} Trend"),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   /// Field dropdown
//                   if (fields.isNotEmpty)
//                     Row(
//                       children: [
//                         const Text('Select Field: '),
//                         const SizedBox(width: 10),
//                         DropdownButton<String>(
//                           value: selectedField,
//                           items: fields
//                               .map((f) =>
//                                   DropdownMenuItem(value: f, child: Text(f)))
//                               .toList(),
//                           onChanged: (val) {
//                             setState(() {
//                               selectedField = val;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   const SizedBox(height: 20),

//                   /// Chart
//                   Expanded(
//                     child: data.isEmpty
//                         ? const Center(child: Text("No data available"))
//                         : BarChart(
//                             BarChartData(
//                               alignment: BarChartAlignment.spaceAround,
//                               maxY: maxY,
//                               barTouchData: BarTouchData(
//                                 enabled: true,
//                                 touchCallback: (event, response) {
//                                   if (event is FlTapUpEvent &&
//                                       response?.spot != null) {
//                                     showValueDialog(
//                                         data[response!.spot!.touchedBarGroupIndex]);
//                                   }
//                                 },
//                               ),
//                               titlesData: FlTitlesData(
//                                 leftTitles: AxisTitles(
//                                   sideTitles: SideTitles(showTitles: true),
//                                 ),
//                                 bottomTitles: AxisTitles(
//                                   sideTitles: SideTitles(
//                                     showTitles: true,
//                                     reservedSize: 40,
//                                     getTitlesWidget: (value, meta) {
//                                       final index = value.toInt();
//                                       if (index < 0 || index >= data.length) {
//                                         return const SizedBox.shrink();
//                                       }
//                                       return Padding(
//                                         padding: const EdgeInsets.only(top: 4),
//                                         child: Text(
//                                           data[index]['date'],
//                                           style: const TextStyle(fontSize: 10),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 topTitles: AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false),
//                                 ),
//                                 rightTitles: AxisTitles(
//                                   sideTitles: SideTitles(showTitles: false),
//                                 ),
//                               ),
//                               borderData: FlBorderData(show: false),
//                               barGroups: List.generate(
//                                 data.length,
//                                 (index) {
//                                   final item = data[index];
//                                   final val = item['value'] as double;
//                                   final isCritical = item['isCritical'] == true;
//                                   return BarChartGroupData(
//                                     x: index,
//                                     barRods: [
//                                       BarChartRodData(
//                                         toY: val,
//                                         width: 18,
//                                         color: isCritical ? Colors.red : Colors.blue,
//                                         borderRadius: BorderRadius.circular(4),
//                                       )
//                                     ],
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
