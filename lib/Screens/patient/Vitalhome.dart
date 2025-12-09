import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:healthcare/Screens/patient/addvitals.dart';
import 'package:healthcare/Screens/patient/vitalchartScreen.dart';

class VitalHomeScreen extends StatefulWidget {
  const VitalHomeScreen({super.key});

  @override
  State<VitalHomeScreen> createState() => _VitalHomeScreenState();
}

class _VitalHomeScreenState extends State<VitalHomeScreen> {
  String filter = "ALL";
  List<Map<String, dynamic>> vitals = [];
  int myIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchVitalsFromApi();
  }

  Future<void> _fetchVitalsFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('patientId');//string
      final cookie = prefs.getString('session_cookie');

      if (patientId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vitals/by-patient/$patientId'),
        headers: {
          "Content-Type": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List data = responseData['vitals'];

        //  Group vitals (Temperature and BP)
        Map<String, Map<String, dynamic>> groupedVitals = {};

        for (var v in data) {
          String name = v['vitalName'] ?? '';
          String date = v['date'] ?? '';
          String time = v['time'] ?? '';
          String key = "$name-$date-$time";

          if (!groupedVitals.containsKey(key)) {
            groupedVitals[key] = {
              "type": name == "Temperature"
                  ? "Temp"
                  : name == "Blood Pressure"
                      ? "BP"
                      : "Pulse",
              "fahrenheit": "",
              "celsius": "",
              "systolic": "",
              "diastolic": "",
              "display": "",
              "datetime": "$date • $time",
              "rawDate": date,
              "rawTime": time,
            };
          }

          if (name == "Temperature") {
            if (v['vitalTypeName'] == "Fahrenheit") {
              groupedVitals[key]!["fahrenheit"] = "${v['value']}°F";
            // } else if (v['vitalTypeName'] == "Celsius") {
            //   groupedVitals[key]!["celsius"] = "${v['value']}°C";
            }
          } else if (name == "Blood Pressure") {
            if (v['vitalTypeName'] == "Systolic") {
              groupedVitals[key]!["systolic"] = v['value'].toString();
            } else if (v['vitalTypeName'] == "Diastolic") {
              groupedVitals[key]!["diastolic"] = v['value'].toString();
            }
          } else if (name == "Pulse") {
            groupedVitals[key]!["display"] = "${v['value']} bpm";
          }
        }

        
        List<Map<String, dynamic>> sortedVitals = groupedVitals.values.toList();

        sortedVitals.sort((a, b) {
          DateTime parseDate(String date, String time) {
            try {
              if (date.contains('-')) {
               
                final parts = date.split('-');
                if (parts.first.length == 4) {
                  
                  return DateTime.parse("$date ${time.isNotEmpty ? time : '00:00'}");
                } else {
                  
                  return DateTime(
                    int.parse(parts[2]),
                    int.parse(parts[1]),
                    int.parse(parts[0]),
                  );
                }
              } else if (date.contains('/')) {
                
                final parts = date.split('/');
                if (int.parse(parts[0]) > 12) {
                  
                  return DateTime(
                    int.parse(parts[2]),
                    int.parse(parts[1]),
                    int.parse(parts[0]),
                  );
                } else {
                  
                  return DateTime(
                    int.parse(parts[2]),
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                  );
                }
              }
            } catch (_) {}
            return DateTime(1900);
          }

          final dateA = parseDate(a['rawDate'] ?? '', a['rawTime'] ?? '');
          final dateB = parseDate(b['rawDate'] ?? '', b['rawTime'] ?? '');
          return dateB.compareTo(dateA);
        });

        setState(() {
          vitals = sortedVitals;
        });
      }
    } catch (e) {
      print("Error fetching vitals: $e");
    }
  }

  Future<void> _openAddVitalDialog({
    Map<String, dynamic>? existing,
    int? index,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddVitalDialog(existingVital: existing),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          vitals[index] = result;
        } else {
          vitals.add(result);
        }
      });
    }

    await _fetchVitalsFromApi();
  }

  List<Map<String, dynamic>> get filteredVitals {
    if (filter == "ALL") return vitals;
    return vitals.where((v) => v['type'] == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Vital Sign', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _openAddVitalDialog(),
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            label: const Text("Add Vital", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
         SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildFilterButton("ALL"),
      _buildFilterButton("BP"),
      _buildFilterButton("Pulse"),
      _buildFilterButton("Temp"),
    ],
  ),
),
          const SizedBox(height: 10),
          Expanded(
            child: filteredVitals.isEmpty
                ? const Center(child: Text("No Vitals Added Yet"))
                : ListView.builder(
                    itemCount: filteredVitals.length,
                    itemBuilder: (context, index) {
                      final v = filteredVitals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 2,
                        color: Colors.white,
                        child: ListTile(
                          title: Text(
                            v['type'] == 'BP'
                                ? "Blood Pressure"
                                : v['type'] == 'Pulse'
                                    ? "Pulse Rate"
                                    : "Temperature",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (v['type'] == 'Temp') ...[
                                if ((v['fahrenheit'] ?? '').isNotEmpty)
                                  Text("Fahrenheit: ${v['fahrenheit']}"),
                                // if ((v['celsius'] ?? '').isNotEmpty)
                                //   Text("Celsius: ${v['celsius']}"),
                              ] else if (v['type'] == 'BP') ...[
                                if ((v['systolic'] ?? '').isNotEmpty)
                                  Text("Systolic: ${v['systolic']} mmHg"),
                                if ((v['diastolic'] ?? '').isNotEmpty)
                                  Text("Diastolic: ${v['diastolic']} mmHg"),
                              ] else ...[
                                Text(v['display'] ?? ""),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                v["datetime"] ?? "",
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () => _openAddVitalDialog(
                                  existing: v,
                                  index: index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    vitals.remove(v);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightBlue,
        showSelectedLabels: false,
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VitalsChartScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'Vital'),
          BottomNavigationBarItem(
              icon: Icon(Icons.graphic_eq), label: 'Graph'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String type) {
    final bool isSelected = filter == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(
          type == "BP"
              ? "BP"
              : type == "Temp"
                  ? "Temperature"
                  : type == "Pulse"
                      ? "Pulse Rate"
                      : "ALL",
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => filter = type),
        selectedColor: Colors.deepPurple[100],
      ),
    );
  }
}
