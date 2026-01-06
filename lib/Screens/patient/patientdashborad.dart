import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/patient/familymemberscreen.dart';
import 'package:healthcare/Screens/patient/patient_disease.dart';
import 'package:healthcare/Screens/patient/patient_prescription.dart';
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
  bool isPrimaryProfile = true;

  List<Map<String, dynamic>> notifications = [];
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
    _loadNotificationsPeriodically();
  }

  // ================= Notifications =================
  Future<void> openNotification(Map<String, dynamic> n) async {
    final prefs = await SharedPreferences.getInstance();

    final patientIdStr = prefs.getString('activePatientId');
    if (patientIdStr == null || patientIdStr.isEmpty) {
      print("❌ activePatientId is null");
      return;
    }

    final int? patientId = int.tryParse(patientIdStr);
    if (patientId == null) {
      print("❌ patientId parsing failed");
      return;
    }

    final int? doctorId = n['doctorId'];
    if (doctorId == null) {
      print("❌ doctorId missing in notification");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientPrescriptionScreen(
          doctorId: doctorId,
          patientId: patientId,
        ),
      ),
    );
  }

  Future<String?> _getActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activePatientId');
  }

  Future<void> _loadNotifications() async {
    final patientId = await _getActivePatientId();
    if (patientId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/prescriptions/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      print("🔹 Notification API status: ${response.statusCode}");
      print("🔹 Notification API body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          notifications = data
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (data is Map) {
          notifications = [Map<String, dynamic>.from(data)];
        } else {
          notifications = [];
        }

        setState(() {
          notificationCount = notifications.length;
        });
      } else {
        print(
            "❌ Failed to load notifications: ${response.statusCode} – ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching notifications: $e");
    }
  }

  void _loadNotificationsPeriodically() {
    _loadNotifications();
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _loadNotificationsPeriodically();
    });
  }

  // ================= Patient Info =================
  Future<void> _loadPatientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mainPatientId = prefs.getString('patientId');
    final String? activePatientId =
        prefs.getString('activePatientId') ?? mainPatientId;
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
          isPrimaryProfile = activePatientId == mainPatientId;
        });
      }
    } catch (e) {
      print("Error loading patient info: $e");
    }
  }

  Future<void> _switchBackToPrimary() async {
    final prefs = await SharedPreferences.getInstance();
    final mainPatientId = prefs.getString('patientId');
    if (mainPatientId == null) return;

    await prefs.setString('activePatientId', mainPatientId);
    _loadPatientInfo();
    _loadNotifications();
  }

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

 Future<void> _openFamilyScreen() async {
  final switched = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const FamilyMemberScreen()),
  );

  // If a profile was switched, reload patient info
  if (switched == true) {
    await _loadPatientInfo();
    await _loadNotifications(); // reload notifications for new activePatientId
  }
}

  

  Future<void> _openDiseaseScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientDisease()),
    );
  }

  void _goLabReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LabReport()),
    );
  }

  void _goVital() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VitalHomeScreen()),
    );
  }

  void _goShareData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PatientViewQRCodes()),
    );
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
              // ================= HEADER =================
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
                    // Top Row: Welcome, Notifications, Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (!isPrimaryProfile)
                                TextButton(
                                  onPressed: _switchBackToPrimary,
                                  child: const Text(
                                    "Switch Back",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) {
                                    return ListView.builder(
                                      itemCount: notifications.length,
                                      itemBuilder: (context, index) {
                                        final n = notifications[index];
                                        return ListTile(
                                          title: Text(n['message'] ?? ''),
                                          subtitle: Text(n['timestamp'] ?? ''),
                                          onTap: () {
                                            Navigator.pop(context);
                                            openNotification(n);
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
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
                    // Profile row
                    Row(
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image: DecorationImage(
                              image: profileImageUrl != null
                                  ? NetworkImage(profileImageUrl!)
                                  : const AssetImage(
                                          'assets/images/download.png')
                                      as ImageProvider,
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

          if (index == 2) _goShareData();
          if (index == 3) _openFamilyScreen();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'PHR'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Doctor'),
        ],
      ),
    );
  }
}
