import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientddashboard.dart';
import 'package:healthcare/common_screens/signin.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:qr_flutter/qr_flutter.dart';
 

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  Map<String, dynamic> doctor = {};
  bool doctorLoading = true;
  List<dynamic> patients = [];
  bool isLoading = true;
  int myIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchDoctor();
    fetchPatients();
  }

  Future<void> fetchDoctor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString('doctorId');
      final cookie = prefs.getString('session_cookie');

      if (doctorId == null) {
        setState(() => doctorLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId'),
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
      } else {
        setState(() => doctorLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => doctorLoading = false);
    }
  }

  Future<void> fetchPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString('session_cookie');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/patients'),
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
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const SignIn()),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      doctorLoading ? "Loading..." : doctor["fullName"] ?? "Doctor",
                      style: const TextStyle(
                        fontSize: 26,
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientDetailScreen(patient: p),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.lightBlue,
      //   showSelectedLabels: false,
      //   currentIndex: myIndex,
      //   onTap: (index) {
      //     setState(() {
      //       myIndex = index;
      //     });
      //   },
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'EHR'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Doctor'),
      //   ],
      // ),
    );
  }
}
