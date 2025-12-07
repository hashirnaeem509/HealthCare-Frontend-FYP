import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/config_/api_config.dart';

class VitalsChartScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  final String patientImage;

  const VitalsChartScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.patientImage,
  }) : super(key: key);

  @override
  State<VitalsChartScreen> createState() => _VitalsChartScreenState();
}



 
class _VitalsChartScreenState extends State<VitalsChartScreen> {
  bool loading = true;
  String errorMsg = '';
  List<Map<String, dynamic>> rawVitals = [];
  String selectedVital = 'BP';
  List<String> vitalOptions = ['BP', 'Pulse', 'Temp'];

  @override
  void initState() {
    super.initState();
    fetchVitals();
  }

  Future<void> fetchVitals() async {
    setState(() {
      loading = true;
      errorMsg = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vitals/by-patient/${widget.patientId}'),
        headers: {
          "Content-Type": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['vitals'] as List;

        setState(() {
          rawVitals = List<Map<String, dynamic>>.from(data);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = "Failed to fetch vitals.";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Error fetching vitals: $e";
      });
    }
  }

  // Filter vitals by selected type
  List<Map<String, dynamic>> get filteredVitals {
    final lower = selectedVital.toLowerCase();

    return rawVitals.where((v) {
      final name = v['vitalName'].toString().toLowerCase();
      final type = v['vitalTypeName'].toString().toLowerCase();

      if (lower == 'bp') {
        return name.contains('blood') ||
            type.contains('systolic') ||
            type.contains('diastolic');
      }
      if (lower == 'pulse') {
        return name.contains('pulse') || type.contains('bpm');
      }
      if (lower == 'temp') {
        return name.contains('temp') || type.contains('celsius');
      }
      return false;
    }).toList();
  }

  // Group vitals by typeName (same as Angular)
  Map<String, List<Map<String, dynamic>>> groupByType(List<Map<String, dynamic>> vitals) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var v in vitals) {
      final type = v['vitalTypeName'] ?? v['vitalName'] ?? 'Unknown';
      grouped.putIfAbsent(type, () => []).add(v);
    }
    return grouped;
  }

  // Convert vitals to FL spots
  List<FlSpot> mapToSpots(List<Map<String, dynamic>> vitals) {
    final valid = vitals.where((v) {
      return v['value'] != null &&
          double.tryParse(v['value'].toString()) != null &&
          v['date'] != null;
    }).toList();

    valid.sort((a, b) =>
        DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    return valid.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        double.parse(e.value['value'].toString()),
      );
    }).toList();
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
      ));
    }

    final filtered = filteredVitals;

    if (filtered.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Vitals Chart")),
        body: const Center(
            child: Text(
          "No vitals available for chart.",
          style: TextStyle(fontSize: 16),
        )),
      );
    }

    final grouped = groupByType(filtered);

    final sortedDates = filtered
        .where((v) => v['date'] != null)
        .map((v) => DateTime.parse(v['date']))
        .toList()
      ..sort();

    List<Color> colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];

    int colorIndex = 0;

    final List<LineChartBarData> datasets = grouped.entries.map((entry) {
      return LineChartBarData(
        spots: mapToSpots(entry.value),
        isCurved: true,
        barWidth: 3,
        color: colors[colorIndex++ % colors.length],
        dotData: FlDotData(show: true),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vitals Chart"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.patientImage.isNotEmpty
                      ? NetworkImage(widget.patientImage)
                      : const AssetImage('assets/images/download.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.patientName,
                    style:
                        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            DropdownButton<String>(
              value: selectedVital,
              isExpanded: true,
              items: vitalOptions
                  .map((v) =>
                      DropdownMenuItem(value: v, child: Text(v.toUpperCase())))
                  .toList(),
              onChanged: (val) => setState(() => selectedVital = val!),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= sortedDates.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('dd MMM').format(sortedDates[index]),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, interval: 5)),
                  ),
                  lineBarsData: datasets,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
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
                      color: colors[index % colors.length],
                    ),
                    const SizedBox(width: 4),
                    Text(label),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
