import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/Screens/patient/sharedata.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) async {
          if (isScanned) return;

          final barcode = capture.barcodes.first;
          final String? code = barcode.rawValue;
          if (code == null) return;

          isScanned = true;

          try {
            // 🔹 Decode QR JSON
            final Map<String, dynamic> doctorData = jsonDecode(code);

            // 🔹 Save scanned doctor
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              "selectedDoctor",
              jsonEncode({
                "doctorId": doctorData["doctorId"],
                "tenantId": doctorData["tenantId"],
                "fullName": doctorData["fullName"],
                "specialization": doctorData["specialization"],
              }),
            );

            // ✅ NAVIGATION TO SHARE SCREEN
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => ShareScreen()),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid QR Code")),
            );
            isScanned = false;
          }
        },
      ),
    );
  }
}
