import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ✅ missing import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Doctordashboard(),
    );
  }
}

class Doctordashboard extends StatefulWidget {
  const Doctordashboard({super.key});

  @override
  State<Doctordashboard> createState() => _DoctordashboardState();
}

class _DoctordashboardState extends State<Doctordashboard> {
  List<dynamic> patients = [];
  bool isLoading = true;

  String doctorName = "";
  String doctorImage = "";

  // ✅ Doctor info fetch
  Future<void> fetchDoctorInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId'); // local storage se uthaya

    if (userId != null) {
      final url = Uri.parse("http://192.168.0.101:8080/doctor/$userId");

      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          doctorName = data['fullName'] ?? "Unknown";
          doctorImage = data['profileImageUrl'] ?? "";
        });
      } else {
        print("Error fetching doctor info: ${response.statusCode}");
      }
    }
  }

  // ✅ Patients fetch
  Future<void> fetchPatients() async {
    final url = Uri.parse("http://192.168.0.101:8080/doctor/patients");
    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });

      if (response.statusCode == 200) {
        setState(() {
          patients = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception("Failed to load patients: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDoctorInfo();
    fetchPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Text(
                  'Doctordashboard',
                  style: const TextStyle(
                    fontSize: 26,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: doctorImage.isNotEmpty
                          ? NetworkImage(doctorImage)
                          : null,
                      child: doctorImage.isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Hi Dr. $doctorName",
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search Patients",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.lightBlue,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text("Patient: ${patient['fullName']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("DOB: ${patient['dob']}"),
                              Text("Gender: ${patient['gender']}"),
                              Text(
                                "Diseases: ${(patient['diseases'] as List).isEmpty ? "None" : (patient['diseases'] as List).join(', ')}",
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
    );
  }
}
