import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import "package:image/image.dart" as img;
import 'package:healthcare/Screens/ui/LabReportService.dart';

class ScanReportScreen extends StatefulWidget {
  final int labTestId; // ✅ Lab Test ID from LabReport screen
  const ScanReportScreen({super.key, required this.labTestId});

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final LabReportService _service = LabReportService();

  File? _selectedImage;
  bool _loading = false;
  String _status = "";

  // 📸 Pick Image
  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Source"),
        content: const Text("Pick image from camera or gallery"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _status = "✅ Image selected successfully!";
        });
      }
    } catch (e) {
      debugPrint("❌ Image picking error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // 🗜️ Compress Image
  Future<File> _compressImage(File file) async {
    try {
      final dir = Directory.systemTemp;
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux) {
        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) return file;
        final resized = img.copyResize(decoded, width: 1000);
        final compressedBytes = img.encodeJpg(resized, quality: 70);
        return await File(targetPath).writeAsBytes(compressedBytes);
      } else {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: 70,
          minWidth: 800,
          minHeight: 800,
          format: CompressFormat.jpeg,
        );
        return result != null ? File(result.path) : file;
      }
    } catch (e) {
      debugPrint("❌ Compression error: $e");
      return file;
    }
  }

  // 🧠 Extract Data (Upload + OCR)
  Future<void> _extractData() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _status = "⏳ Compressing and uploading image...";
    });

    try {
      // Step 1️⃣ Compress
      final compressedImage = await _compressImage(_selectedImage!);

      // Step 2️⃣ Upload & Extract
      final ocrData =
          await _service.uploadAndExtractOCR(compressedImage, widget.labTestId);

      if (!mounted) return;

      // ✅ Step 3️⃣ Return OCR data back to LabReport screen
      Navigator.pop(context, ocrData); // 🔹 CHANGED HERE
    } catch (e) {
      setState(() => _status = "❌ Extraction failed: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }


  void _onCancel() {
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📄 Scan Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(

          children: [

            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_selectedImage!, height: 250, fit: BoxFit.cover),
              ),

            const SizedBox(height: 20),

            Text(
              _status,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),


            _buildButton("📷 Capture / Upload", Colors.blue, _pickImage),


            _buildButton("🧠 Extract Data", Colors.green, _extractData,


                disabled: _loading),


            _buildButton("❌ Cancel", Colors.red, _onCancel),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildButton(String text, Color color, VoidCallback onTap,
      {bool disabled = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
