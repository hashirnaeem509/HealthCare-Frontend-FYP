import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/addvitals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/Screens/ui/config/api_config.dart';

class VitalHomeScreen extends StatefulWidget {
  const VitalHomeScreen({super.key});

  @override
  State<VitalHomeScreen> createState() => _VitalHomeScreenState();
}

class _VitalHomeScreenState extends State<VitalHomeScreen> {
  String filter = "ALL";
  List<Map<String, dynamic>> vitals = [];

  int myIndex = 0; // for BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _fetchVitalsFromApi();
  }

  /// ✅ Fetch vitals from backend using correct endpoint
  Future<void> _fetchVitalsFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getInt('patientId');
      final cookie = prefs.getString('session_cookie');

      if (patientId == null) {
        print("❌ Patient ID not found in SharedPreferences");
        return;
      }

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

        print("🧾 Response data: $data"); // 👈 debug print

        setState(() {
          vitals = data.map<Map<String, dynamic>>((v) {
            String type = "Unknown";

            // 👇 Correctly detect vital type
            if (v['vitalName'] == "Temperature") {
              type = "Temp";
            } else if (v['vitalName'] == "Pulse") {
              type = "Pulse";
            } else if (v['vitalName'] == "Blood Pressure" ||
                v['vitalTypeName'] == "Systolic" ||
                v['vitalTypeName'] == "Diastolic") {
              type = "BP";
            }

            String displayValue = v['value']?.toString() ?? '';
            if (type == "Temp" && v['vitalTypeName'] == "Fahrenheit") {
              displayValue += "°F";
            } else if (type == "Temp" && v['vitalTypeName'] == "Celsius") {
              displayValue += "°C";
            } else if (type == "Pulse") {
              displayValue += " bpm";
            }

            return {
              "type": type,
              "display": displayValue,
              "datetime": v['date'] != null
                  ? "${v['date']} • ${v['time'] ?? ''}"
                  : '',
            };
          }).toList();
        });

        print("✅ Loaded ${vitals.length} vitals from API");
      } else {
        print("❌ Failed to load vitals: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching vitals: $e");
    }
  }

  Future<void> _openAddVitalDialog({Map<String, dynamic>? existing, int? index}) async {
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

    await _fetchVitalsFromApi(); // reload
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("ALL"),
              _buildFilterButton("BP"),
              _buildFilterButton("Pulse"),
              _buildFilterButton("Temp"),
            ],
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
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            v['type'] == 'BP'
                                ? "Blood Pressure"
                                : v['type'] == 'Pulse'
                                    ? "Pulse Rate"
                                    : "Temperature",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${v['display']}\n${v['datetime']}"),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openAddVitalDialog(existing: v, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
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
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Vital'),
          BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Graph'),
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
