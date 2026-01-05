import 'package:flutter/material.dart';
import 'package:healthcare/services/prescription_Service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class DoctorPatientPrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const DoctorPatientPrescriptionScreen({super.key, required this.patient});

  @override
  State<DoctorPatientPrescriptionScreen> createState() =>
      _DoctorPatientPrescriptionScreenState();
}

class _DoctorPatientPrescriptionScreenState
    extends State<DoctorPatientPrescriptionScreen> {
  String selectedMedicine = '';
  String selectedDosage = '';
  String notes = '';
  int? doctorId;

  final PrescriptionService _service = PrescriptionService();

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDoctorId = prefs.getString('doctorId');
    if (storedDoctorId == null) {
      // Doctor not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor not logged in')),
      );
      Navigator.pop(context);
      return;
    }
    setState(() {
      doctorId = int.tryParse(storedDoctorId);
    });
  }

  Future<void> _savePrescription() async {
    if (selectedMedicine.isEmpty || selectedDosage.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select medicine and dosage')));
      return;
    }

    if (doctorId == null) return;

    final success = await _service.savePrescription(
      doctorId: doctorId!,
      patientId: widget.patient['id'],
      medicine: selectedMedicine,
      dosage: selectedDosage,
      notes: notes,
    );

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Prescription saved')));
      _resetForm();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to save prescription')));
    }
  }

  void _resetForm() {
    setState(() {
      selectedMedicine = '';
      selectedDosage = '';
      notes = '';
    });
  }

  void _goBack() {
    Navigator.pop(context, widget.patient); // similar to Angular state
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text(patient['fullName'] ?? 'Patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Patient Info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: patient['profileImageUrl'] != null
                      ? NetworkImage(patient['profileImageUrl'])
                      : const AssetImage('assets/images/download.png') as ImageProvider,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient['fullName'] ?? '', style: const TextStyle(fontSize: 20)),
                    Text('${patient['gender'] ?? ''} | ${patient['dob'] ?? ''}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medicine Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Medicine'),
              value: selectedMedicine.isNotEmpty ? selectedMedicine : null,
              items: ['Panadol', 'Brufen', 'Disprin']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedMedicine = val ?? ''),
            ),
            const SizedBox(height: 16),

            // Dosage Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Dosage'),
              value: selectedDosage.isNotEmpty ? selectedDosage : null,
              items: ['1', '1+1', '1+1+1']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedDosage = val ?? ''),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => notes = val,
              controller: TextEditingController(text: notes),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              
              onPressed: _savePrescription,
              style: ElevatedButton.styleFrom(
                          //  shape: const CircleBorder(),
                            backgroundColor: Colors.lightBlue,
                            foregroundColor: Colors.white,),
              child: const Text('Save Prescription'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
         backgroundColor: Colors.lightBlue,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Prescription'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Patient'),
        ],
        onTap: (index) {
          if (index == 0) Navigator.pop(context); // go home
        },
      ),
    );
  }
}