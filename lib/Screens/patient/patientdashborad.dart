import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/patient/familymemberscreen.dart';
import 'package:healthcare/Screens/patient/patient_disease.dart';
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
  bool isPrimaryProfile = true; // track if active patient is primary (logged-in)

    // ✅ Notifications
  List<Map<String, dynamic>> notifications = [];
  int notificationCount = 0;
  bool showNotifications = false;


  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
    _loadNotificationsPeriodically();
  }

void toggleNotifications() {
    setState(() {
      showNotifications = !showNotifications;
    });
  }

   void openNotification(Map<String, dynamic> n) {
    final patientId = _getActivePatientId();
    // Navigate to prescription or relevant page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientViewQRCodes(), // example
      ),
    );
    }

    Future<String?> _getActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activePatientId');
  }

 // ✅ Load notifications from API
  Future<void> _loadNotifications() async {
    final patientId = await _getActivePatientId();
    if (patientId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/prescriptions/$patientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          notifications = data.cast<Map<String, dynamic>>();
          notificationCount = notifications.length;
        });
      } else {
        print("Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  void _loadNotificationsPeriodically() {
    // Initial fetch
    _loadNotifications();
    // Auto refresh every 10 sec
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadNotificationsPeriodically();
      }
    });
  }
  // Load active patient info
 Future<void> _loadPatientInfo() async {
  final prefs = await SharedPreferences.getInstance();

  final String? mainPatientId = prefs.getString('patientId'); // logged-in patient
  final String? activePatientId = prefs.getString('activePatientId') ?? mainPatientId;
  final String? cookie = prefs.getString('session_cookie');

  if (activePatientId == null || activePatientId.isEmpty) return;

  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patient/$activePatientId'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'Cookie': cookie,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        fullName = data['fullName'] ?? "Unknown";
        profileImageUrl = ApiConfig.resolveImageUrl(data['profileImageUrl']);
        isPrimaryProfile = activePatientId == mainPatientId; // compare IDs
      });
    }
  } catch (e) {
    print("Error loading patient info: $e");
  }
}


  // Logout
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

  // Navigate to Family screen and wait for selection
  Future<void> _openFamilyScreen() async {
    // Open FamilyMemberScreen and wait for switch
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FamilyMemberScreen()),
    );
    // After returning, reload active patient info
    _loadPatientInfo();
  }

  Future<void> _openDiseaseScreen() async{

    await Navigator.push(context, MaterialPageRoute(builder: (context)=> const PatientDisease()),);
  }
  // Navigate to Lab Report
  void _goLabReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LabReport()),
    );
  }

  // Navigate to Vitals
  void _goVital() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VitalHomeScreen()),
    );
  }

  // Navigate to Doctor / QR
  void _goShareData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PatientViewQRCodes()),
    );
  }

  Future<void> _switchBackToPrimary() async {
  final prefs = await SharedPreferences.getInstance();
  final mainPatientId = prefs.getString('patientId');
  if (mainPatientId == null) return;

  await prefs.setString('activePatientId', mainPatientId);
  _loadPatientInfo(); // reload main patient info
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
                height: 180,
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       Expanded(
  child: Row(
    children: [
      Flexible(
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
      if (!isPrimaryProfile)
        TextButton(
          onPressed: _switchBackToPrimary,
          child: const Text(
            "Switch Back",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
    ],
  ),
),Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.blueGrey,
                              size: 28,
                            ),
                            onPressed: toggleNotifications,
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  notificationCount.toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            )
                        ],
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
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image: profileImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image:
                                        AssetImage('assets/images/download.png'),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fullName != null
                                ? "Welcome, $fullName"
                                : "Welcome",
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

              // PHR Buttons
              if (myIndex == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 500),
                  
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _goLabReport,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(30),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.note_add, size: 25),
                            SizedBox(height: 2),
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _goVital,
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
                            SizedBox(height: 2),
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _openFamilyScreen,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(30),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.family_restroom, size: 25),
                            SizedBox(height: 7),
                            Text(
                              'Family',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                       const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _openDiseaseScreen,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(30),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sick, size: 25),
                            SizedBox(height: 3),
                            Text(
                              'Disease',
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
            _goShareData();
            //_openFamilyScreen();
          } else if (index == 3) {
           _openFamilyScreen();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'PHR'),
        //  BottomNavigationBarItem(
          //    icon: Icon(Icons.family_restroom), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Doctor'),
        ],
      ),
    );
  }
}
