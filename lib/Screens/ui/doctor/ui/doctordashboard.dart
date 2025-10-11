import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/Screens/ui/config/api_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DoctorDashboard(), // default home screen
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

  Future<void> fetchPatients() async {
    final String url = '${ApiConfig.baseUrl}/doctor/patients';
    //final url = Uri.parse("http://192.168.43.233:8080/doctor/patients");

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          if (cookie != null) "Cookie": cookie, // Cookie attach here
        },
      );

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
    fetchPatients(); // screen load hote hi call hoga
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Profile image (top-left)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: AssetImage("assets/images/doctor.png"),
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Dashboard title (center)
                  const Center(
                    child: Text(
                      'Doctor Dashboard',
                      style: TextStyle(
                        fontSize: 26,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
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
                  ),
                ],
              ),
            ),

            // Patients list
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
      ),
    );
  }
}
