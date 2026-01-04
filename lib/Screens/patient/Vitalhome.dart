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

  // ================= FETCH + GROUP =================
  Future<void> _fetchVitalsFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('activePatientId');
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

        Map<String, Map<String, dynamic>> groupedVitals = {};

        for (var v in data) {
          final name = v['vitalName'];
          final date = v['date'];
          final time = v['time'];
          final key = "$name-$date-$time";

          if (!groupedVitals.containsKey(key)) {
            groupedVitals[key] = {
              "type": name == "Temperature"
                  ? "Temp"
                  : name == "Blood Pressure"
                      ? "BP"
                      : "Pulse",
              "items": [],
              "datetime": "$date • $time",
              "rawDate": date,
              "rawTime": time,
            };
          }

          groupedVitals[key]!['items'].add({
            "obsVId": v['obsVId'],
            "value": v['value'],
            "typeName": v['vitalTypeName'],
            "isCritical": v['isCritical'] ?? false,
          });
        }

        setState(() {
          vitals = groupedVitals.values.toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching vitals: $e");
    }
  }

  // ================= EDIT SINGLE ITEM =================
  Future<void> _editVitalItem(
    Map<String, dynamic> v,
    Map<String, dynamic> item,
  ) async {
    final controller =
        TextEditingController(text: item['value'].toString());

    final newValue = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit ${item['typeName']}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (newValue == null || newValue.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    await http.put(
      Uri.parse('${ApiConfig.baseUrl}/vitals/observed'),
      headers: {
        "Content-Type": "application/json",
        if (cookie != null) "Cookie": cookie,
      },
      body: jsonEncode({
        "obsVId": item['obsVId'],
        "value": num.parse(newValue),
        "date": v['rawDate'],
        "time": v['rawTime'],
      }),
    );

    await _fetchVitalsFromApi();
  }

  // ================= DELETE =================
  Future<void> _deleteVital(Map<String, dynamic> v) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    for (var item in v['items']) {
      await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/vitals/observed/${item['obsVId']}'),
        headers: {
          "Content-Type": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
      );
    }

    await _fetchVitalsFromApi();
  }

  List<Map<String, dynamic>> get filteredVitals {
    if (filter == "ALL") return vitals;
    return vitals.where((v) => v['type'] == filter).toList();
  }

  // ================= UI =================
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
            child: ListView.builder(
              itemCount: filteredVitals.length,
              itemBuilder: (context, index) {
                final v = filteredVitals[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      v['type'] == 'BP'
                          ? "Blood Pressure"
                          : v['type'] == 'Pulse'
                              ? "Pulse Rate"
                              : "Temperature",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...v['items'].map<Widget>((item) {
                          return GestureDetector(
                            onTap: () => _editVitalItem(v, item),
                            child: Row(
                              children: [
                                Text(
                                  "${item['value']} ${item['typeName']}",
                                  style: TextStyle(
                                    color: item['isCritical']
                                        ? Colors.red
                                        : Colors.black,
                                    fontWeight: item['isCritical']
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (item['isCritical'])
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.warning,
                                        size: 16, color: Colors.red),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 6),
                        Text(v['datetime'],
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteVital(v),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: myIndex,
        onTap: (i) {
          setState(() => myIndex = i);
          if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const VitalsChartScreen()),
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

  // ================= HELPERS =================
  Future<void> _openAddVitalDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const AddVitalDialog(),
    );
    await _fetchVitalsFromApi();
  }

  Widget _buildFilterButton(String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(type),
        selected: filter == type,
        onSelected: (_) => setState(() => filter = type),
      ),
    );
  }
}
