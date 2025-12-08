import 'package:flutter/material.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientlabreport.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientvital.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientvitalchart.dart';

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int myIndex = 0;

  void _logout() {
    Navigator.pop(context);
  }

  void goVitals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Patientvital(
          patientId: widget.patient['id'],
          patientName: widget.patient['fullName'] ?? 'Patient',
          patientImage: widget.patient['profileImageUrl'] ?? '',
          patientGender: widget.patient['gender'] ?? '',
          patientDOB: widget.patient['dob'] ?? '',
        ),
      ),
    );
  }

  void goLabReports() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PatientLabReportsScreen(patient: widget.patient),
    ),
  );
}


  void goPrescriptions() {
    // Pass patientId and patient object if needed
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceholderScreen(title: "Prescriptions", patient: widget.patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return Scaffold(
      body: Stack(
        children: [
          // Top Blue Section
          Container(
            height: 165,
            width: double.infinity,
            color: Colors.lightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      "Patient Details",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                      onPressed: _logout,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: patient['profileImageUrl'] != null && patient['profileImageUrl'].isNotEmpty
                          ? NetworkImage(patient['profileImageUrl'])
                          : const AssetImage('assets/images/download.png') as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      patient['fullName'] ?? 'Welcome',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Patient Details
          Padding(
            padding: const EdgeInsets.only(top: 180, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Full Name: ${patient['fullName']}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("DOB: ${patient['dob']}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text("Gender: ${patient['gender']}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  "Diseases: ${(patient['diseases'] as List).isEmpty ? 'None' : (patient['diseases'] as List).join(', ')}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: goLabReports,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(30),
                        backgroundColor: Colors.lightBlue,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.note_add, size: 25), SizedBox(height: 3), Text('Lab Reports', style: TextStyle(fontSize: 8))],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: goVitals,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(30),
                        backgroundColor: Colors.lightBlue,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.monitor_heart, size: 25), SizedBox(height: 3), Text('Vitals Sign', style: TextStyle(fontSize: 8))],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: goPrescriptions,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(30),
                        backgroundColor: Colors.lightBlue,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.medication, size: 25), SizedBox(height: 3), Text('Prescription', style: TextStyle(fontSize: 8))],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        showSelectedLabels: false,
        backgroundColor: Colors.lightBlue,
        onTap: (index) {
        //   if (index == 2) {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => const VitalsChartScreenUI()),
        //     );
        //   }
        // 
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Vital'),
          BottomNavigationBarItem(icon: Icon(Icons.graphic_eq), label: 'Graph'),
        ],
      ),
    );
  }
}

// Placeholder screen to represent Lab Reports or Prescriptions
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final Map<String, dynamic> patient;

  const PlaceholderScreen({super.key, required this.title, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Screen for $title of ${patient['fullName']}')),
      
    );
  }
}
