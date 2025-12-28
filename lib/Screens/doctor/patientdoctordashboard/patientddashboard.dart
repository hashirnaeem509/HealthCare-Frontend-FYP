
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/doctor/doctorPrescription.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientlabreport.dart';
import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientvital.dart';
import 'package:healthcare/config_/api_config.dart';


class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int myIndex = 0;
  bool showButtons = false;

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
      builder: (context) => PatientLabReportsScreen(patient: widget.patient, reportId: '', patientId: '',),
    ),
  );
}


  void goPrescriptions() {
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPatientPrescriptionScreen( patient: widget.patient),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    return Scaffold(
      body: Stack(
        children: [
          // Top Blue Section (unchanged)
          Container(
            height: 165,
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16),
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
                   Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    image: patient['profileImageUrl'] != null &&
            patient['profileImageUrl'].toString().isNotEmpty
        ? DecorationImage(
            image: NetworkImage(
              ApiConfig.resolveImageUrl(patient['profileImageUrl']),
            ),
            fit: BoxFit.cover,
          )
        : const DecorationImage(
            image: AssetImage('assets/images/download.png'),
            fit: BoxFit.cover,
          ),
  ),
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
              ],
            ),
          ),

         
          if (showButtons)
            Padding(
              padding: const EdgeInsets.only(top: 550),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: goLabReports,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(30),
                      backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_add, size: 25),
                        SizedBox(height: 3),
                        Text('Lab Reports', style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: goVitals,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(30),
                      backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monitor_heart, size: 25),
                        SizedBox(height: 3),
                        Text('Vitals Sign', style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: goPrescriptions,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(30),
                     backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication, size: 25),
                        SizedBox(height: 3),
                        Text('Prescription', style: TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: myIndex,
        showSelectedLabels: false,
        backgroundColor: Colors.lightBlue,
        onTap: (index) {
          setState(() {
            myIndex = index;
            
            showButtons = index == 1;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'EHR'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Patient'),
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
