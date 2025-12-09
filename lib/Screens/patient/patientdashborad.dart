import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/patient/qr_code.dart';
import 'package:healthcare/common_screens/signin.dart';
import 'package:healthcare/Screens/patient/LabReport.dart';
import 'package:healthcare/Screens/patient/Vitalhome.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/config_/api_config.dart';

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

  //  Patient info load from API
 Future<void> _loadPatientInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final patientId = prefs.getString('patientId'); 
  final cookie = prefs.getString('session_cookie');

  if (patientId == null || patientId.isEmpty) {
    print(" No patientId found!");
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
      print(" Patient info loaded: $fullName");
    } else {
      print(" Failed to load patient info: ${response.statusCode}");
    }
  } catch (e) {
    print(" Error loading patient info: $e");
  }
}

  //  Logout function
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
      body: Container(

    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF53B2E8), Colors.white],
      ),
    ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF53B2E8), Colors.white],
      ),
    ),
                height: 165,
              // width: MediaQuery.of(context).size.width,
               width: double.infinity,
              //  color: const Color.fromARGB(255, 133, 202, 234),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
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
          
                    
                    Row(
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
        
            Expanded(       // <-- FIX ADDED
        child: Text(
          fullName != null ? "Welcome, $fullName" : "Welcome",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
            ),
          ],
        )
        
                  ],
                ),
              ),
          
              //  Buttons
              if (myIndex == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LabReport(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(30),
          
                        ),child: const Column(
                          mainAxisSize: MainAxisSize.min, // content fit karega
                          children: [
                            Icon(Icons.note_add, size: 25),
                            SizedBox(height: 3),
                            Text(
                              'Lab Reports',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        
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
                          padding: const EdgeInsets.all(30), 
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Icon(Icons.monitor_heart, size: 25),
                            SizedBox(height: 3),
                            Text(
                              'Vitals Sign',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
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
            MaterialPageRoute(builder: (context) =>  PatientViewQRCodes()),
          );
        }
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
