

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:healthcare/models/labs_reports.dart';

import 'package:healthcare/models/vital_model.dart';

import 'package:healthcare/services/LabReportService.dart';
import 'package:healthcare/services/phrsharingService.dart';
import 'package:healthcare/services/vital_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final VitalsService vitalsService = VitalsService();
  final LabReportService reportService = LabReportService();

  String? patientId; // NOW STRING ✔
  String activeFilter = 'ALL';
  DateTime? fromDate;
  DateTime? toDate;

  List<VitalRecord> vitals = [];
  List<PatientReportSummaryDTO> reports = [];

  List<VitalRecord> filteredVitals = [];
  List<PatientReportSummaryDTO> filteredReports = [];

  Map<String, bool> selectedItems = {};
  bool selectAll = false;

  Map<String, dynamic>? doctor;
bool doctorLoading = true;


  String today = DateTime.now().toLocal().toString().split(' ')[0];

  @override
  void initState() {
    super.initState();
    _loadPatient();
    loadSelectedDoctor();
    
  }

 Future<void> loadSelectedDoctor() async {
  final prefs = await SharedPreferences.getInstance();
  final docJson = prefs.getString("selectedDoctor");

  if (docJson != null) {
    final doc = jsonDecode(docJson);
    setState(() {
      doctor = doc;
      doctorLoading = false;
    });
    print("Loaded selected doctor: $doctor");
  } else {
    setState(() {
      doctorLoading = false;
      doctor = null;
    });
    print("No selected doctor found!");
  }
}

  // ---------------- Load patientId safely ----------------
  Future<void> _loadPatient() async {
    final prefs = await SharedPreferences.getInstance();

    /// ✔ Read patientId as STRING
    patientId = prefs.getString("patientId");

    if (patientId == null || patientId!.isEmpty) {
      print(" No patientId found in SharedPreferences!");
      return;
    }

    print("✔ Loaded patientId = $patientId");

    // Ensure session cookie exists (optional but safe)
    final cookie = prefs.getString('session_cookie');
    if (cookie == null) {
      print(" Session cookie missing! Please login again.");
      return;
    }

    // Load data
    await loadVitals();
    await loadReports();
  }

  // ---------------- Load Vitals ----------------
  Future<void> loadVitals() async {
  if (patientId == null || patientId!.isEmpty) {
    print(" patientId is NULL or EMPTY");
    return;
  }

  try {
    final list = await vitalsService.getVitalsByPatient(patientId!);

    setState(() {
      vitals = list;
      filteredVitals = [...vitals];
    });

    print(" Vitals loaded successfully");
  } catch (e) {
    print(" Vitals load error: $e");
  }
}

  // ---------------- Load Reports ----------------
  Future<void> loadReports() async {
    if (patientId == null) return;

    try {
      final list = await reportService.getPatientReportSummaries(patientId!);
      setState(() {
        reports = list;
        filteredReports = [...reports];
      });
    } catch (e) {
      print(" Report load error: $e");
    }
  }

  // ---------------- Filter Options ----------------
  void setFilter(String filter) => setState(() => activeFilter = filter);

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;

      for (int i = 0; i < filteredVitals.length; i++) {
        selectedItems[i.toString()] = selectAll;
      }

      for (int i = 0; i < filteredReports.length; i++) {
        selectedItems['lab-$i'] = selectAll;
      }
    });
  }
void share() async {
  if (doctor == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Please select a doctor first!")));
    return;
  }

  // --- SELECTED VITALS ---
  final selectedVitalsList = filteredVitals
      .asMap()
      .entries
      .where((e) => selectedItems[e.key.toString()] == true)
      .map((e) => e.value)
      .toList();

  // --- SELECTED LAB REPORTS ---
  final selectedReportsList = filteredReports
      .asMap()
      .entries
      .where((e) => selectedItems['lab-${e.key}'] == true)
      .map((e) => e.value)
      .toList();

  if (selectedVitalsList.isEmpty && selectedReportsList.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Please select at least one item")));
    return;
  }

  // --- VITAL PAYLOAD (same as Angular) ---
  final vitalsPayload = selectedVitalsList.map((v) => {
        "vitalName": v.vitalName,
        "vitalTypeName": v.vitalTypeName,
        "value": v.value,
        "date": v.date,
        "time": v.time,
        "isCritical": false,
      }).toList();

  // --- LAB PAYLOAD (EXACT Angular format) ---
  final labsPayload = selectedReportsList.map((r) => {
        "reportId": r.reportId,
        "reportName": r.reportName,
        "reportDate": r.reportDate,
        "reportTime": r.reportTime ?? "00:00:00",
      }).toList();

  try {
    await PhrSharingService.instance.shareData(
      patientId: patientId!,
      doctorId: doctor!["doctorId"].toString(),
      vitals: vitalsPayload,
      labs: labsPayload,
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("✅ Data shared successfully!")));

    setState(() => selectedItems.clear());
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("❌ Failed to share data")));
  }
}


  // void share() {
  //   final selectedVitalsList = filteredVitals
  //       .asMap()
  //       .entries
  //       .where((e) => selectedItems[e.key.toString()] == true)
  //       .map((e) => e.value)
  //       .toList();

  //   final selectedReportsList = filteredReports
  //       .asMap()
  //       .entries
  //       .where((e) => selectedItems['lab-${e.key}'] == true)
  //       .map((e) => e.value)
  //       .toList();

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text("Sharing ${selectedVitalsList.length + selectedReportsList.length} items")),
  //   );
  // }

  String normalizeType(String type) {
    final t = type.trim().toLowerCase();
    if (t.startsWith("blood pressure")) return "Blood Pressure";
    if (t.startsWith("temperature") || t.startsWith("temprature")) return "Temperature";
    if (t.startsWith("pulse")) return "Pulse";
    return type;
  }

  void filterByDate() {
    setState(() {
      final from = fromDate;
      final to = toDate;

      filteredVitals = vitals.where((v) {
        final vDate = DateTime.tryParse(v.date);
        if (vDate == null) return false;
        if (from != null && vDate.isBefore(from)) return false;
        if (to != null && vDate.isAfter(to)) return false;
        return true;
      }).toList();

      filteredReports = reports.where((r) {
        final rDate = DateTime.tryParse(r.reportDate);
        if (rDate == null) return false;
        if (from != null && rDate.isBefore(from)) return false;
        if (to != null && rDate.isAfter(to)) return false;
        return true;
      }).toList();
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Share Vitals & Reports")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // DOCTOR CARD
            // Container(
            //   padding: EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //       color: const Color.fromARGB(255, 6, 166, 241),
            //       borderRadius: BorderRadius.circular(8)),
            //   child: Row(
            //     children: [
            //       Image.asset('assets/images/download.png', width: 50),
            //       SizedBox(width: 12),
            //       Text("Dr. Sheikh Qasim Khokhar",
            //           style: TextStyle(
            //               fontWeight: FontWeight.bold, fontSize: 16)),
            //     ],
            //   ),
            // ),
            // DOCTOR CARD
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [Color(0xFF53B2E8), Colors.white],
      //  borderRadius: BorderRadius.circular(8)),
      ),
    ),
  // decoration: BoxDecoration(
  //     color: const Color.fromARGB(255, 6, 166, 241),
  //     borderRadius: BorderRadius.circular(8)),
  child: Row(
    children: [
      CircleAvatar(
        radius: 25,
        backgroundImage: doctor != null && doctor!['profileImageUrl'] != null
            ? NetworkImage(doctor!['profileImageUrl'])
            : AssetImage('assets/images/download.png') as ImageProvider,
      ),
      SizedBox(width: 12),
      doctorLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
              doctor != null ? doctor!['fullName'] ?? 'Unknown Doctor' : 'No Doctor',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white),
            ),
    ],
  ),
),


            SizedBox(height: 12),

            // FILTER CHIPS
            Wrap(
              spacing: 8,
              children: [
                'ALL',
                'Blood Pressure',
                'Temperature',
                'Pulse',
                'Lab Reports'
              ]
                  .map((f) => ChoiceChip(
                        label: Text(f),
                        selected: activeFilter == f,
                        onSelected: (_) => setFilter(f),
                      ))
                  .toList(),
            ),
            SizedBox(height: 12),

            // DATE FILTERS
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("From:"),
                      SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: fromDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            setState(() => fromDate = d);
                            filterByDate();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(fromDate != null
                              ? fromDate!.toLocal().toString().split(' ')[0]
                              : 'Select Date'),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("To:"),
                      SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: toDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            setState(() => toDate = d);
                            filterByDate();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(toDate != null
                              ? toDate!.toLocal().toString().split(' ')[0]
                              : 'Select Date'),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // SELECT ALL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(today),
                Row(
                  children: [
                    Text("Select All"),
                    Checkbox(
                        value: selectAll, onChanged: (val) => toggleSelectAll(val))
                  ],
                )
              ],
            ),
            SizedBox(height: 12),

            // VITALS LIST
            if (activeFilter != 'Lab Reports')
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredVitals.length,
                itemBuilder: (context, index) {
                  final v = filteredVitals[index];
                  if (activeFilter != 'ALL' &&
                      normalizeType(v.vitalName) != activeFilter) {
                    return SizedBox.shrink();
                  }

                  return Card(
                    color: const Color.fromARGB(255, 108, 180, 231),
                    child: ListTile(
                      title: Text(v.vitalName),
                      subtitle: Text("${v.value} ${v.vitalTypeName}"),
                      leading: normalizeType(v.vitalName) == 'Temperature'
                          ? Icon(Icons.thermostat)
                          : normalizeType(v.vitalName) == 'Blood Pressure'
                              ? Icon(Icons.monitor_heart)
                              : normalizeType(v.vitalName) == 'Pulse'
                                  ? Icon(Icons.favorite)
                                  : null,
                      trailing: Checkbox(
                        value: selectedItems[index.toString()] ?? false,
                        onChanged: (val) =>
                            setState(() => selectedItems[index.toString()] = val ?? false),
                      ),
                    ),
                  );
                },
              ),

            // LAB REPORTS
            if (activeFilter == 'ALL' || activeFilter == 'Lab Reports')
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredReports.length,
                itemBuilder: (context, index) {
                  final r = filteredReports[index];
                  return Card(
                    color: const Color.fromARGB(255, 86, 127, 197),
                    child: ListTile(
                      title: Text(r.reportName),
                      subtitle: Text("Lab Report"),
                      leading: Icon(Icons.insert_drive_file),
                      trailing: Checkbox(
                        value: selectedItems['lab-$index'] ?? false,
                        onChanged: (val) =>
                            setState(() => selectedItems['lab-$index'] = val ?? false),
                      ),
                    ),
                  );
                },
              ),

            SizedBox(height: 10),

            // Bottom Buttons
            // Bottom Buttons
Padding(
  padding: const EdgeInsets.only(bottom: 20.0), // add some space from bottom
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Back")),
      ElevatedButton(
        onPressed: share,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue),
        child: Text("Share"),
      ),
    ],
  ),
),

          ],
        ),
      ),
    );
  }
}
