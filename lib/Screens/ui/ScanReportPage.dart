// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:healthcare/Screens/ui/LabReportService.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:shared_preferences/shared_preferences.dart';


// class ScanReportPage extends StatefulWidget {
//   final int labTestId;
//   const ScanReportPage({super.key, required this.labTestId});

//   @override
//   State<ScanReportPage> createState() => _ScanReportPageState();
// }

// class _ScanReportPageState extends State<ScanReportPage> {
//   File? _selectedFile;
//   String? _previewPath;
//   bool _loading = false;
//   String _statusText = '';
//   final ImagePicker _picker = ImagePicker();
//   final _labService = LabReportService();

//   // Capture or Upload Image
//   Future<void> _openCamera() async {
//     final pickedFile = await _picker.pickImage(
//       source: ImageSource.camera,
//       maxWidth: 1000,
//       maxHeight: 1200,
//       imageQuality: 85,
//     );
//     if (pickedFile == null) return;

//     setState(() => _statusText = 'Preparing image...');
//     File? compressed = await _compressImage(File(pickedFile.path));
//     setState(() {
//       _selectedFile = compressed;
//       _previewPath = compressed?.path;
//     });
//   }

//   /// 🗜️ Compress Image
//   Future<File?> _compressImage(File file) async {
//     final targetPath =
//         '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

//     final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
//       file.path,
//       targetPath,
//       quality: 70,
//       minWidth: 1000,
//     );
//     return compressed != null ? File(compressed.path) : null;
//   }

//   //  Save & Upload to OCR API
//   Future<void> _onSave() async {
//     if (_selectedFile == null) {
//       _showAlert('📸 Please capture or upload a report first!');
//       return;
//     }

//     setState(() {
//       _loading = true;
//       _statusText = 'Uploading image...';
//     });

//     try {
//       final ocrData =
//           await _labService.scanOCRReport(_selectedFile!, widget.labTestId);

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('ocrData', jsonEncode(ocrData));

//       setState(() {
//         _statusText = 'Extracting data...';
//       });

//       await Future.delayed(const Duration(milliseconds: 800));
//       _showAlert(' Scan complete! Returning to Lab Report...');
//       Navigator.pop(context);
//     } catch (e) {
//       _showAlert(' OCR failed. Please try again.');
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   // Cancel
//   void _onCancel() => Navigator.pop(context);

//   void _showAlert(String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('📸 Scan or Upload Lab Report')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(25),
//         child: Column(
//           children: [
//             if (_previewPath != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(File(_previewPath!)),
//               ),
//             if (_statusText.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Text(
//                   _statusText,
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ),
//             const SizedBox(height: 20),
//             _buildButton('📷 Capture / Upload', Colors.blue, _openCamera),
//             _buildButton('💾 Save & Extract', Colors.green, _onSave,
//                 disabled: _loading),
//             _buildButton(' Cancel', Colors.red, _onCancel),
//             if (_loading) ...[
//               const SizedBox(height: 20),
//               const CircularProgressIndicator(),
//               const SizedBox(height: 10),
//               const Text('Processing image, please wait...'),
//             ]
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildButton(String text, Color color, VoidCallback onTap,
//       {bool disabled = false}) {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: ElevatedButton(
//         onPressed: disabled ? null : onTap,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           padding: const EdgeInsets.all(12),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         ),
//         child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
//       ),
//     );
//   }
// }
