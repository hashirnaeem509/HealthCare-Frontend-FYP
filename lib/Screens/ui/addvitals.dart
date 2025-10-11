import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthcare/Screens/ui/config/api_config.dart';

class AddVitalDialog extends StatefulWidget {
  final Map<String, dynamic>? existingVital;

  const AddVitalDialog({super.key, this.existingVital});

  @override
  State<AddVitalDialog> createState() => _AddVitalDialogState();
}

class _AddVitalDialogState extends State<AddVitalDialog> {
  String selectedVital = "";
  final systolicController = TextEditingController();
  final diastolicController = TextEditingController();
  final fahrenheitController = TextEditingController();
  final celsiusController = TextEditingController();
  final pulseController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  int? patientId;
  String patientGender = '';
  int? patientAge;

  @override
  void initState() {
    super.initState();
    _loadPatientIdAndFetchInfo();

    if (widget.existingVital != null) {
      final v = widget.existingVital!;
      selectedVital = v['type'];
      if (selectedVital == "BP") {
        final parts = v['display'].split('/');
        systolicController.text = parts[0].trim();
        diastolicController.text = parts[1].trim();
      } else if (selectedVital == "Temp") {
        fahrenheitController.text = v['display'].replaceAll("°F", "");
      } else if (selectedVital == "Pulse") {
        pulseController.text = v['display'].replaceAll(" bpm", "");
      }
    }
  }

  /// ✅ Step 1: Load patientId & Fetch patient info
  Future<void> _loadPatientIdAndFetchInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('patientId');
    print("🔍 Loaded patientId from SharedPreferences: $id");
    if (id != null) {
      patientId = id;
      await _fetchPatientInfo(id);
    } else {
      print("❌ No patientId found in storage!");
    }
  }

  /// ✅ Step 2: Fetch patient gender & age (with Cookie)
  Future<void> _fetchPatientInfo(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patient/$id'),
      headers: {
        "Content-Type": "application/json",
        if (cookie != null) "Cookie": cookie, // ✅ Send session cookie
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        patientGender = data['gender'] ?? '';
        if (data['dob'] != null) {
          final birthDate = DateTime.parse(data['dob']);
          final now = DateTime.now();
          int age = now.year - birthDate.year;
          if (now.month < birthDate.month ||
              (now.month == birthDate.month && now.day < birthDate.day)) {
            age--;
          }
          patientAge = age;
        } else {
          patientAge = null;
        }
      });
      print("✅ Patient info loaded: Gender=$patientGender, Age=$patientAge");
    } else {
      print("❌ Failed to fetch patient info (${response.statusCode})");
    }
  }

  /// 📅 DateTime picker for vitals
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(context: context, initialTime: selectedTime);
    if (time == null) return;

    setState(() {
      selectedDate = date;
      selectedTime = time;
    });
  }

  /// 💾 Save Vital to Backend (with Cookie)
  Future<void> _save() async {
    if (selectedVital.isEmpty || patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select vital type and make sure patient is loaded")),
      );
      return;
    }

    final dateStr = "${selectedDate.toIso8601String().split('T')[0]}";
    final timeStr =
        "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00";

    List<Map<String, dynamic>> vitalsPayload = [];

    if (selectedVital == "BP") {
      vitalsPayload.addAll([
        {
          "vitalName": "Blood Pressure",
          "vitalTypeName": "Systolic",
          "value": systolicController.text,
          "date": dateStr,
          "time": timeStr
        },
        {
          "vitalName": "Blood Pressure",
          "vitalTypeName": "Diastolic",
          "value": diastolicController.text,
          "date": dateStr,
          "time": timeStr
        }
      ]);
    } else if (selectedVital == "Temp") {
      vitalsPayload.add({
        "vitalName": "Temperature",
        "vitalTypeName": "Fahrenheit",
        "value": fahrenheitController.text,
        "date": dateStr,
        "time": timeStr
      });
    } else if (selectedVital == "Pulse") {
      vitalsPayload.add({
        "vitalName": "Pulse",
        "vitalTypeName": "BPM",
        "value": pulseController.text,
        "date": dateStr,
        "time": timeStr
      });
    }

    final payload = {
      "patientId": patientId,
      "gender": patientGender,
      "age": patientAge,
      "vitals": vitalsPayload
    };

    print("📤 Submitting vital payload: $payload");

    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/vitals/submitVitals'),
      headers: {
        "Content-Type": "application/json",
        if (cookie != null) "Cookie": cookie, // ✅ Send session cookie
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Vital saved successfully")),
      );

      String display = selectedVital == "BP"
          ? "${systolicController.text} / ${diastolicController.text}"
          : selectedVital == "Temp"
              ? "${fahrenheitController.text}°F"
              : "${pulseController.text} bpm";

      Navigator.pop(context, {
        "type": selectedVital,
        "display": display,
        "datetime": "$dateStr • $timeStr",
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save (${response.statusCode})")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingVital == null ? "➕ Add Vital" : "✏️ Edit Vital"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedVital.isEmpty ? null : selectedVital,
              decoration: const InputDecoration(labelText: "Vital Type"),
              items: const [
                DropdownMenuItem(value: "BP", child: Text("🩺 Blood Pressure")),
                DropdownMenuItem(value: "Temp", child: Text("🌡️ Temperature")),
                DropdownMenuItem(value: "Pulse", child: Text("❤️ Pulse Rate")),
              ],
              onChanged: (val) => setState(() => selectedVital = val!),
            ),
            const SizedBox(height: 8),
            if (selectedVital == "BP") ...[
              TextField(
                controller: systolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Systolic (mmHg)"),
              ),
              TextField(
                controller: diastolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Diastolic (mmHg)"),
              ),
            ] else if (selectedVital == "Temp") ...[
              TextField(
                controller: fahrenheitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Temperature (°F)"),
              ),
              TextField(
                controller: celsiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Temperature (°C)"),
              ),
            ] else if (selectedVital == "Pulse") ...[
              TextField(
                controller: pulseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Pulse Rate (BPM)"),
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(
                  "${selectedDate.year}-${selectedDate.month}-${selectedDate.day} ${selectedTime.format(context)}"),
              onPressed: _pickDateTime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: _save, child: const Text("Save")),
      ],
    );
  }
}
