import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/common_screens/signin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:qr_flutter/qr_flutter.dart'; // QR Package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DoctorDashboard(),
    );
  }
}

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  // -------------------------------
  // 🔥 Doctor Info Variables
  // -------------------------------
  Map<String, dynamic> doctor = {};
  bool doctorLoading = true;

  // -------------------------------
  // Patient list variables
  // -------------------------------
  List<dynamic> patients = [];
  bool isLoading = true;

  // ================================
  // 🔥 Fetch Doctor Info (UPDATED)
  // ================================
  // ---------------- Fetch doctor by ID ----------------
  Future<void> fetchDoctor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString('doctorId'); // Angular style
      final cookie = prefs.getString('session_cookie');

      if (doctorId == null) {
        print("No doctorId found in SharedPreferences");
        setState(() => doctorLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId'), // Angular style URL
        headers: {
          "Accept": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          doctor = body;
          doctorLoading = false;
        });
        print("Doctor fetched: $doctor");
      } else {
        setState(() => doctorLoading = false);
        print("Failed to fetch doctor: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => doctorLoading = false);
      print("Doctor fetch error: $e");
    }
  }

  // ---------------- QR Code ----------------
  void _showDoctorQr() {
    if (doctorLoading || doctor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor info not loaded")),
      );
      return;
    }

    final idValue = doctor["id"] ?? doctor["_id"] ?? doctor["doctorId"];
    String qrData = jsonEncode({
      "doctorId": idValue,
      "fullName": doctor["fullName"] ?? "",
      "specialization": doctor["specialization"] ?? "",
      "profileImageUrl": doctor["profileImageUrl"] ?? "",
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Doctor QR Code"),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 240,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }


  // ================================
  // Fetch Patients
  // ================================
  Future<void> fetchPatients() async {
    final String url = '${ApiConfig.baseUrl}/doctor/patients';

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          patients = json.decode(response.body);
          isLoading = false;
        });
      } else {
        isLoading = false;
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      isLoading = false;
      print("Exception: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDoctor();
    fetchPatients();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
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

                  // TOP ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear(); // clear session
          // Navigate to login or home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SignIn()), // replace with login page if exists
          );
        },
        icon: const Icon(Icons.arrow_back, size: 30),
        color: Colors.black87,
      ),

                       
                        IconButton(
                          onPressed: _showDoctorQr,
                          icon: const Icon(Icons.qr_code, size: 35),
                          color: Colors.black87,
                        ),

                        // Profile image
                       CircleAvatar(
  radius: 45,
  backgroundColor: Colors.white,
  child: ClipOval(
    child: doctor["profileImageUrl"] != null &&
            doctor["profileImageUrl"].toString().isNotEmpty
        ? Image.network(
            doctor["profileImageUrl"],
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          )
        : Image.asset(
            "assets/images/defaultimage.png",
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
  ),
),

                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Title
                  Center(
                    child: Text(
                     // 'Doctor Dashboard',
                     doctorLoading ? "Loading..." : doctor["fullName"] ?? "Doctor",
                      style: const TextStyle(
                        fontSize: 26,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

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

            // PATIENT LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final p = patients[index];

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
                            title: Text("Patient: ${p['fullName']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("DOB: ${p['dob']}"),
                                Text("Gender: ${p['gender']}"),
                                Text(
                                  "Diseases: ${(p['diseases'] as List).isEmpty ? "None" : (p['diseases'] as List).join(', ')}",
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
