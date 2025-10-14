import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/Signin.dart';
import 'package:healthcare/Screens/ui/Vitalhome.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/Screens/ui/config/api_config.dart';

class Patientdashborad extends StatefulWidget {
  const Patientdashborad({super.key});

  @override
  State<Patientdashborad> createState() => _PatientdashboradState();
}

class _PatientdashboradState extends State<Patientdashborad> {
  int myIndex = 0;

  String? fullName;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
  }

  // ✅ Patient info load from API
  Future<void> _loadPatientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getInt('patientId');
    final cookie = prefs.getString('session_cookie');

    if (patientId == null) {
      print("⚠️ No patientId found!");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          fullName = data['fullName'] ?? "Unknown";
          profileImageUrl = data['profileImageUrl'];
        });
        print("✅ Patient info loaded: $fullName");
      } else {
        print("❌ Failed to load patient info: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error loading patient info: $e");
    }
  }

  // ✅ Logout function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔷 Header
          Container(
            height: 165,
            width: double.infinity,
            color: Colors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row with title + logout
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          "Patient Dashboard",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: "Logout",
                      onPressed: _logout,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Patient info row
                Row(
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        image:
                            profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
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
                    const SizedBox(width: 10),
                    Text(
                      fullName != null ? "Welcome, $fullName" : "Welcome",
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Buttons
          if (myIndex == 1)
            Padding(
              padding: const EdgeInsets.only(top: 500),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.note_add, size: 30),
                  ),
                  const SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VitalHomeScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.science, size: 30),
                  ),
                ],
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
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'PHR',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Doctor'),
        ],
      ),
    );
  }
} 