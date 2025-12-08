// import 'package:flutter/material.dart';
// import 'package:healthcare/Screens/doctor/doctordashboard.dart';
// import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientddashboard.dart';
// import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientvital.dart';
// import 'package:healthcare/Screens/doctor/patientdoctordashboard/patientvitalchart.dart';
// import 'package:healthcare/Screens/patient/LabReport.dart';
// import 'package:healthcare/Screens/patient/ScanReport.dart';
// import 'package:healthcare/Screens/patient/Vitalhome.dart';
// import 'package:healthcare/Screens/patient/addvitals.dart';
// import 'package:healthcare/Screens/patient/patientdashborad.dart';
// import 'package:healthcare/Screens/patient/vitalchartScreen.dart';
// import 'package:healthcare/common_screens/profile.dart';
// //import 'package:healthcare/common_screens/profile.dart';
// import 'package:healthcare/common_screens/registration.dart';
// import 'package:healthcare/common_screens/signin.dart';
// import 'package:healthcare/common_screens/splashscrren.dart';




// class AppRoutes {
//   static const splash = '/';
//   static const signup = '/signup';
//   static const login = '/login';
//   static const profile = '/profile';
//   static const patientDashboard = '/patient-dashboard';
//   static const doctorDashboard = '/doctor-dashboard';
//   static const vitals = '/vitals';
//   static const addVitalDialog = '/add-vital-dialog';
//   static const vitalsChart = '/vitals-chart';
//   static const labReport = '/lab-report';
//   static const scanReport = '/scan-report';
//   static const shareData = '/share-data';
//   static const qrcodeGenerator = '/qrcode-generator';
//   static const patientViewQRCodes = '/patient-view-qrcodes';
//   static const doctorPatientDashboard = '/doctor-patient-dashboard';
//   static const doctorVitals = '/doctor-vitals';
//   static const doctorVitalsChart = '/doctor-vitals-chart';
//   static const doctorPatientLabReports = '/doctor-patient-lab-reports';

//   static Route<dynamic> generateRoute(RouteSettings settings) {
//     final args = settings.arguments;

//     switch (settings.name) {
//       case splash:
//         return MaterialPageRoute(builder: (_) => const SplashScreen());

//       case signup:
//         return MaterialPageRoute(builder: (_) => const Registration());

//       case login:
//         return MaterialPageRoute(builder: (_) => const SignIn());

//       case profile:
//         return MaterialPageRoute(builder: (_) => const ProfilePage(role: '', userId: '',));

//       case patientDashboard:
//         return MaterialPageRoute(builder: (_) => const Patientdashborad());

//       case doctorDashboard:
//         return MaterialPageRoute(builder: (_) => const DoctorDashboard());

//       case vitals:
//         return MaterialPageRoute(builder: (_) => const VitalHomeScreen());

//       case addVitalDialog:
//         return MaterialPageRoute(builder: (_) => const AddVitalDialog());

//       case vitalsChart:
//         return MaterialPageRoute(builder: (_) => const VitalsChartScreen());

//       case labReport:
//         return MaterialPageRoute(builder: (_) => const LabReport());

//       // *************** WITH PARAMETERS *************** //

//       case scanReport:
//         return MaterialPageRoute(
//           builder: (_) => ScanReportScreen(labTestId: args as int),
//         );

//       case doctorPatientDashboard:
//         return MaterialPageRoute(
//           builder: (_) => PatientDetailScreen(patientId: args as int),
//         );

//       case doctorVitals:
//         return MaterialPageRoute(
//           builder: (_) => Patientvital(patientId: args as int),
//         );

//       case doctorVitalsChart:
//         return MaterialPageRoute(
//           builder: (_) => DoctorVitalsChart(patientId: args as int),
//         );

//       case doctorPatientLabReports:
//         return MaterialPageRoute(
//           builder: (_) => DoctorPatientLabReports(patientId: args as int),
//         );

//       // SCREENS WITHOUT PARAMETERS
//       case shareData:
//         return MaterialPageRoute(builder: (_) => const ShareData());

//       case qrcodeGenerator:
//         return MaterialPageRoute(builder: (_) => const QrcodeGenerator());

//       case patientViewQRCodes:
//         return MaterialPageRoute(builder: (_) => const PatientViewQRCodes());

//       default:
//         return MaterialPageRoute(
//           builder: (_) => const Scaffold(
//             body: Center(child: Text("Route not found")),
//           ),
//         );
//     }
//   }
// }
