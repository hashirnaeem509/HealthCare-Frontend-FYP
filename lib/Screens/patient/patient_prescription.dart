import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:http/http.dart' as http;

class PatientPrescriptionScreen extends StatefulWidget {
  final int doctorId;
  final int patientId;
  final String? patientName;
  final String? patientImage;

  const PatientPrescriptionScreen({
    super.key,
    required this.doctorId,
    required this.patientId,
    this.patientName,
    this.patientImage,
  });

  @override
  State<PatientPrescriptionScreen> createState() =>
      _PatientPrescriptionScreenState();
}

class _PatientPrescriptionScreenState extends State<PatientPrescriptionScreen> {
  bool loading = true;
  String errorMsg = '';

  String patientName = '';
  String patientImage = '';

  List<Map<String, dynamic>> medicines = [];
  String? note;

  @override
  void initState() {
    super.initState();

    // Pre-set patient info if passed from previous screen
    if (widget.patientName != null) patientName = widget.patientName!;
    if (widget.patientImage != null) patientImage = widget.patientImage!;

    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      errorMsg = '';
      medicines = [];
      note = null;
    });

    try {
      // ================= PATIENT INFO =================
      final patientRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/patient/${widget.patientId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (patientRes.statusCode == 200) {
        final p = jsonDecode(patientRes.body);
        setState(() {
          patientName = p['fullName'] ?? patientName;
          patientImage = (p['profileImageUrl'] != null &&
                  p['profileImageUrl'].toString().isNotEmpty)
              ? p['profileImageUrl']
              : 'assets/images/patient.png';
        });
      }

      // ================= PRESCRIPTION =================
      final presRes = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/prescriptions/details/${widget.doctorId}/${widget.patientId}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (presRes.statusCode == 200) {
        final Map<String, dynamic> prescription = jsonDecode(presRes.body);

        setState(() {
          medicines = prescription['medicines'] != null
              ? List<Map<String, dynamic>>.from(prescription['medicines'])
              : [];
          note = prescription['note']?['message'] ?? '';
        });
      } else {
        setState(() => errorMsg = 'Failed to load prescription');
      }
    } catch (e) {
      setState(() => errorMsg = 'Error loading data: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Prescription")),
        body: Center(
          child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Prescription Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ===== Patient Info =====
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: patientImage.startsWith('http')
                      ? NetworkImage(patientImage)
                      : AssetImage(patientImage) as ImageProvider,
                  onBackgroundImageError: (_, __) {
                    setState(() {
                      patientImage = 'assets/images/patient.png';
                    });
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== Medicines =====
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "💊 Medicines",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (medicines.isEmpty)
                      const Text(
                        "No medicines prescribed",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ...medicines.map((m) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Text(
                              m['name'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m['dosage'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.orange),
                            ),
                            if ((m['note'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  m['note'],
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.blue),
                                ),
                              ),
                          ],
                        )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== Doctor Note =====
            if (note != null && note!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📝 Doctor's Note",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
