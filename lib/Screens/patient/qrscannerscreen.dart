// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';

// class QRScannerScreen extends StatefulWidget {
//   const QRScannerScreen({super.key});

//   @override
//   _QRScannerScreenState createState() => _QRScannerScreenState();
// }

// class _QRScannerScreenState extends State<QRScannerScreen> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;

//   @override
//   void reassemble() {
//     super.reassemble();
//     if (controller != null) {
//       controller!.pauseCamera();
//       controller!.resumeCamera();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Scan QR Code")),
//       body: SizedBox.expand(
//         child: QRView(
//           key: qrKey,
//           onQRViewCreated: _onQRViewCreated,
//         ),
//       ),
//     );
//   }

//   void _onQRViewCreated(QRViewController ctrl) {
//     controller = ctrl;
//     controller!.scannedDataStream.listen((scanData) {
//       controller!.pauseCamera();
//       Navigator.pop(context, scanData.code);
//     });
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
// }
