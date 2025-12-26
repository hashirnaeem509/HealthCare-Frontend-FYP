import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/patient/sharedata.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientViewQRCodes extends StatefulWidget {
  const PatientViewQRCodes({super.key});

  @override
  _PatientViewQRCodesState createState() => _PatientViewQRCodesState();
}

class _PatientViewQRCodesState extends State<PatientViewQRCodes> {
  bool loading = true;
  List doctors = [];

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/doctor/all"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        doctors = data.map((doc) {
          final qrData = jsonEncode({
            "doctorId": doc["id"],
            "tenantId": doc["tenantId"],
            "fullName": doc["fullName"],
            "specialization": doc["specialization"],
            "profileImageUrl":
                doc["profileImageUrl"] ?? "assets/icons/doctor.png",
          });

          return {
            ...doc,
            "profileImageUrl":
                doc["profileImageUrl"] ?? "assets/icons/doctor.png",
            "qrData": qrData
          };
        }).toList();
      }
    } catch (e) {
      print("Failed to fetch doctors: $e");
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> selectDoctor(Map doc) async {
    final prefs = await SharedPreferences.getInstance();

    final selectedDoctor = {
      "doctorId": doc["id"],
      "tenantId": doc["tenantId"],
      "fullName": doc["fullName"],
      "specialization": doc["specialization"]
    };

    await prefs.setString("selectedDoctor", jsonEncode(selectedDoctor));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShareScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // scanner ke liye package

// AppBar ko replace karein:
appBar: AppBar(
  title: Text("Available Doctors"),
  actions: [
    IconButton(
      icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PatientViewQRCodes()),
        );
      },
    ),
  ],
),

     body: loading
    ? Center(child: CircularProgressIndicator())
    : doctors.isEmpty
        ? Center(child: Text("No doctors available"))
        : Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: doctors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.4, 
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final doc = doctors[index];
                return GestureDetector(
                  onTap: () => selectDoctor(doc),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          color: Colors.black12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    image: DecorationImage(
      // image: (doc["profileImageUrl"] != null && doc["profileImageUrl"] != "")
      //     ? NetworkImage(doc["profileImageUrl"])
      //     : const AssetImage('assets/images/download.png') as ImageProvider,
      image: const AssetImage('assets/images/download.png'),

      fit: BoxFit.cover,
    ),
  ),
),


                        SizedBox(height: 6),
                        Text(
                          doc["fullName"],
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          doc["specialization"],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        QrImageView(
                          data: doc["qrData"],
                          size: 250
                          , // smaller QR code
                          version: QrVersions.auto,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

    );
  }
}
