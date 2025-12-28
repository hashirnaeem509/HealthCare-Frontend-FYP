import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:healthcare/config_/api_config.dart';

class VitalsChartScreen extends StatefulWidget {
  const VitalsChartScreen({super.key});

  @override
  State<VitalsChartScreen> createState() => _VitalsChartScreenState();
}

class _VitalsChartScreenState extends State<VitalsChartScreen> {
  bool loading = true;
  String errorMsg = '';
  String selectedVital = 'temperature';
  List<Map<String, dynamic>> rawVitals = [];
  List<String> vitalOptions = ['blood pressure', 'temperature', 'pulse'];

  String patientName = '';
  //String patientImage = '';
  String? profileImageUrl = '';
  


  @override
  void initState() {
    super.initState();
    _fetchPatientAndVitals();
  }

  Future<void> _fetchPatientAndVitals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
     // final patientId = prefs.getInt('patientId');
      final patientId = prefs.getString('activePatientId');
      final cookie = prefs.getString('session_cookie');

      if (patientId == null) {
        setState(() {
          loading = false;
          errorMsg = 'No patient ID found';
        });
        return;
      }

      final patientRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      if (patientRes.statusCode == 200) {
        final pData = jsonDecode(patientRes.body);
        setState(() {
          
      
        patientName = pData['fullName'] ?? '';
       // patientImage = pData['profileImageUrl'] ?? '';
       profileImageUrl = ApiConfig.resolveImageUrl(pData['profileImageUrl']);
      

        });
      }

      final vitalsRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vitals/by-patient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      if (vitalsRes.statusCode == 200) {
        final data = jsonDecode(vitalsRes.body);
        rawVitals = List<Map<String, dynamic>>.from(data['vitals'] ?? []);
      } else {
        errorMsg = 'Failed to load vitals.';
      }
    } catch (e) {
      errorMsg = 'Error fetching vitals: $e';
    }

    setState(() => loading = false);
  }

  Map<String, List<Map<String, dynamic>>> _groupBySubtype(
    List<Map<String, dynamic>> vitals,
  ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var v in vitals) {
      final subtype = (v['vitalTypeName'] ?? v['vitalName'] ?? 'Unknown')
          .toString();
      groups.putIfAbsent(subtype, () => []).add(v);
    }
    return groups;
  }

  List<FlSpot> _mapVitalsToSpots(List<Map<String, dynamic>> vitals) {
    final entries =
        vitals
            .where((v) => v['value'] != null && v['date'] != null)
            .map(
              (v) => MapEntry(
                DateTime.tryParse(v['date']) ?? DateTime.now(),
                double.tryParse(v['value'].toString()) ?? 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final filtered = rawVitals.where((v) {
      final name = (v['vitalName'] ?? '').toString().toLowerCase();
      final type = (v['vitalTypeName'] ?? '').toString().toLowerCase();
       if (type.contains('celsius')) {
    return false; 
  }

      if (selectedVital == 'blood pressure') {
        return name.contains('blood pressure') ||
            type.contains('systolic') ||
            type.contains('diastolic');
       
      } else if (selectedVital == 'temperature') {
    return name.contains('temp') || type.contains('fahrenheit');
      
      } else {
        return name.contains('pulse') || type.contains('bpm');
      }
    }).toList();

    if (filtered.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Vitals Chart")),
        body: const Center(child: Text("No vitals data available")),
      );
    }

    final grouped = _groupBySubtype(filtered);
    final sortedDates =
        filtered
            .where((v) => v['date'] != null)
            .map((v) => DateTime.tryParse(v['date']))
            .whereType<DateTime>()
            .toList()
          ..sort();

    final colorPalette = [Colors.redAccent, Colors.blueAccent];
    int colorIndex = 0;
    final List<LineChartBarData> datasets = [];

    grouped.forEach((subtype, list) {
      datasets.add(
        LineChartBarData(
          isCurved: true,
          spots: _mapVitalsToSpots(list),
          barWidth: 3,
          color: colorPalette[colorIndex % colorPalette.length],
          dotData: FlDotData(show: true),
        ),
      );
      colorIndex++;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vitals Chart"),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatientAndVitals,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                       // ignore: unnecessary_null_comparison
                        image: profileImageUrl != null && profileImageUrl!.isNotEmpty
        ? DecorationImage(
            image: NetworkImage(profileImageUrl!),
            fit: BoxFit.cover,
          )
        : const DecorationImage(
            image: AssetImage('assets/images/download.png'),
            fit: BoxFit.cover,
          ),
                          ),
                    ),
                
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientName.isNotEmpty ? patientName : "Patient",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            DropdownButton<String>(
              value: selectedVital,
              isExpanded: true,
              items: vitalOptions
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedVital = val!),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: LineChart(
                LineChartData(
                  /////
                  // minY: 70,
                  // maxY: 120,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateFormat(
                            'dd MMM\nhh:mm a',
                          ).format(sortedDates[index]);
                          return Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              date,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize:
                            40, //  Added space so Y-axis labels don’t overlap
                      ),
                    ),
                  ),
                  lineBarsData: datasets,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateFormat(
                            'dd MMM yyyy hh:mm a',
                          ).format(sortedDates[spot.x.toInt()]);
                          final type = spot.bar.color == Colors.redAccent
                              ? 'Fahrenheit'
                              : 'Celsius';
                          return LineTooltipItem(
                            '$type\n$date\nValue: ${spot.y.toStringAsFixed(1)}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: grouped.keys.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: colorPalette[index % colorPalette.length],
                    ),
                    const SizedBox(width: 4),
                    Text(label, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}