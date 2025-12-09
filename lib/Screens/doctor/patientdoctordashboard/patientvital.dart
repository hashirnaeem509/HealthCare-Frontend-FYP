import 'package:flutter/material.dart';
import 'package:healthcare/Screens/doctor/doctordashboard.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientvitalchart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:healthcare/config_/api_config.dart';
import 'package:healthcare/Screens/patient/addvitals.dart';

class Patientvital extends StatefulWidget {
  final int patientId;
  final String patientName;
  final String patientImage;
  final String patientGender;
  final String patientDOB;

  const Patientvital({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientImage,
    required this.patientGender,
    required this.patientDOB,
  });

  @override
  State<Patientvital> createState() => _PatientvitalState();
}

class _PatientvitalState extends State<Patientvital> {
  String filter = "ALL";
  List<Map<String, dynamic>> vitals = [];
  bool loading = true;
  String errorMsg = '';

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

        
        Map<String, Map<String, dynamic>> grouped = {};
        for (var v in data) {
          String key = "${v['vitalName']}-${v['date']}-${v['time']}";
          if (!grouped.containsKey(key)) {
            grouped[key] = {
              "type": normalizeType(v['vitalName']),
              "values": [],
              "date": v['date'],
              "time": v['time'],
            };
          }
          grouped[key]!["values"].add({
            "value": v['value'],
            "typeName": v['vitalTypeName'],
          });
        }

        List<Map<String, dynamic>> sortedVitals = grouped.values.toList();
        sortedVitals.sort((a, b) {
          DateTime parseDate(String date, String time) =>
              DateTime.tryParse("$date $time") ?? DateTime(1900);
          return parseDate(b['date'], b['time'])
              .compareTo(parseDate(a['date'], a['time']));
        });

        setState(() {
          vitals = sortedVitals;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = 'Failed to fetch vitals.';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = 'Error fetching vitals: $e';
      });
    }
  }

  String normalizeType(String type) {
    final t = type.toLowerCase();
    if (t.contains('blood')) return 'BP';
    if (t.contains('temp')) return 'Temp';
    if (t.contains('pulse')) return 'Pulse';
    return type;
  }

List<Map<String, dynamic>> get filteredVitals {
  List<Map<String, dynamic>> result = vitals;

  // Apply type filter
  if (filter != "ALL") {
    result = result.where((v) => v['type'] == filter).toList();
  }

  
  result = result.where((v) {
    final values = v['values'] as List;
    
    return values.any((val) =>
        val['typeName'].toString().toLowerCase() != 'celsius');
  }).toList();

  return result;
}

  // List<Map<String, dynamic>> get filteredVitals {
  //   if (filter == "ALL") return vitals;
  //   return vitals.where((v) => v['type'] == filter).toList();
  // }

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
      await fetchVitals();
    }
  }

void goGraph() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VitalsChartScreens(
        patientId: widget.patientId,      
        patientName: widget.patientName,  
        patientImage: widget.patientImage 
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_circle, color: Colors.blue),
        //     onPressed: () => _openAddVitalDialog(),
        //   ),
        // ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                       decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
                      child: Row(
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
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.patientName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("${widget.patientGender} | ${widget.patientDOB}"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: ["ALL", "BP", "Pulse", "Temp"]
                            .map((type) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: filter == type,
                                    onSelected: (_) => setState(() => filter = type),
                                    selectedColor: Colors.blue[100],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    
                    Expanded(
                      child: filteredVitals.isEmpty
                          ? const Center(child: Text("No Vitals Added Yet"))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: filteredVitals.length,
                              itemBuilder: (context, index) {
                                final v = filteredVitals[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text(
                                      v['type'] == 'BP'
                                          ? "Blood Pressure"
                                          : v['type'] == 'Pulse'
                                              ? "Pulse"
                                              : "Temperature",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (var val in v['values'])
      if (val['typeName'].toString().toLowerCase() != 'celsius')
        Text("${val['typeName']}: ${val['value']}"),
    const SizedBox(height: 4),
    Text("${v['date']} • ${v['time']}",
        style: const TextStyle(fontSize: 12, color: Colors.grey)),
  ],
),

                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      // children: [
                                      //   IconButton(
                                      //     icon: const Icon(Icons.edit, color: Colors.blue),
                                      //     onPressed: () => _openAddVitalDialog(existing: v, index: index),
                                      //   ),
                                      //   IconButton(
                                      //     icon: const Icon(Icons.delete, color: Colors.red),
                                      //     onPressed: () => setState(() => vitals.removeAt(index)),
                                      //   ),
                                      // ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        showSelectedLabels: false,
        backgroundColor: Colors.lightBlue,
        onTap: (index) {
          if (index == 2) {
            goGraph();
          }
          else if(index == 0){
            godoctordashborad();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'EHR'),
          BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Graph'),
        ],
      ),
    );
  }
  
  void godoctordashborad() {
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DoctorDashboard()));
    
  }
}
