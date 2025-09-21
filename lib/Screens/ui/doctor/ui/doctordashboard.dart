import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DoctorDashboard(), //  default home screen
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<dynamic> patients = [];
  bool isLoading = true;

  //  API call function
  Future<void> fetchPatients() async {
    final url = Uri.parse("http://192.168.0.101:8080/doctor/patients"); // apna backend URL

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
        print("Error: ${response.statusCode}");
  print("Response body: ${response.body}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Exception: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPatients(); //  screen load hote hi call hoga
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //  Header
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Doctor Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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

          //  Patients list
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
