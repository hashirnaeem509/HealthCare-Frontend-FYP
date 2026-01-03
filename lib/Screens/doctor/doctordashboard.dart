import 'dart:async';
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

  List<dynamic> notifications = [];
  int notificationCount = 0;
  Timer? notificationTimer;

  @override
  void initState() {
    super.initState();
    fetchDoctor();
    fetchPatients();
    fetchNotifications();

    notificationTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => fetchNotifications());
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString('doctorId');
      final cookie = prefs.getString('session_cookie');

      if (doctorId == null) return;

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId/notifications'),
        headers: {
          "Accept": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          notifications = json.decode(res.body) ?? [];
          notificationCount = notifications.length;
        });
      }
    } catch (e) {
      debugPrint("Notification error ❌ $e");
    }
  }

  Future<void> fetchDoctor() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorId = prefs.getString('doctorId');
    final cookie = prefs.getString('session_cookie');

    if (doctorId == null) return;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/doctor/$doctorId'),
      headers: {
        "Accept": "application/json",
        if (cookie != null) "Cookie": cookie,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        doctor = json.decode(response.body);
        doctorLoading = false;
      });
    }
  }

  Future<void> fetchPatients() async {
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
    }
  }

  void showNotificationDialog() {
    setState(() => notificationCount = 0);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notifications"),
        content: SizedBox(
          width: double.maxFinite,
          child: notifications.isEmpty
              ? const Center(child: Text("No notifications"))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (_, i) {
                    final n = notifications[i];
                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(n['patientName'] ?? ''),
                      subtitle: Text(n['message'] ?? ''),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Widget notificationBell() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 30),
          onPressed: showNotificationDialog,
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
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  void _showDoctorQr() {
    final idValue = doctor["id"] ?? doctor["_id"] ?? doctor["doctorId"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Doctor QR Code"),
        content: QrImageView(
          data: jsonEncode({"doctorId": idValue}),
          size: 240,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlueAccent, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () async {
                            final prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignIn()),
                            );
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code),
                              onPressed: _showDoctorQr,
                            ),
                            notificationBell(),
                          ],
                        ),
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: doctor['profileImageUrl'] != null
                              ? NetworkImage(ApiConfig.resolveImageUrl(
                                  doctor['profileImageUrl']))
                              : const AssetImage(
                                      'assets/images/download.png')
                                  as ImageProvider,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doctor["fullName"] ?? "Doctor",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
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
                      itemBuilder: (_, i) {
                        final p = patients[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: p['profileImageUrl'] != null
                                  ? NetworkImage(ApiConfig.resolveImageUrl(
                                      p['profileImageUrl']))
                                  : const AssetImage(
                                          'assets/images/download.png')
                                      as ImageProvider,
                            ),
                            title: Text(p['fullName'] ?? ''),
                            subtitle: Text(
                                "DOB: ${p['dob']} | Gender: ${p['gender']}"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        PatientDetailScreen(patient: p)),
                              );
                            },
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
