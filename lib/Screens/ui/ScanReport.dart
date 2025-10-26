// 📦 IMPORTS
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import "package:image/image.dart" as img; // ✅ for desktop/web compression
import 'package:healthcare/Screens/ui/LabReportService.dart';
import 'package:healthcare/Screens/ui/extractdatascreen.dart';

class ScanReportScreen extends StatefulWidget {
  final int labTestId; // ✅ Ye test id LabReport screen se aayegi
  const ScanReportScreen({super.key, required this.labTestId});

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  final ImagePicker _picker = ImagePicker(); // 📸 image picker init
  final LabReportService _service = LabReportService(); // 🌐 API service class

  File? _selectedImage; // 🖼 selected image file
  bool _loading = false; // ⏳ for showing loader
  String _status = ""; // 🧾 status text for user feedback

  // 📸 Step 1️⃣: Pick Image from Camera or Gallery
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

    if (source == null) return; // user ne cancel kar diya

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // 🗜️ Step 2️⃣: Compress image (works on Windows + Mobile)
  Future<File> _compressImage(File file) async {
    try {
      if (!await file.exists()) {
        debugPrint("⚠️ File not found: ${file.path}");
        return file;
      }

      final originalSize = (await file.length()) / 1024;
      debugPrint("📷 Original size: ${originalSize.toStringAsFixed(2)} KB");

      final dir = Directory.systemTemp;
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 💻 Desktop/Web Compression using `image` package
      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux) {
        debugPrint("💻 Using pure Dart compression for desktop/web...");

        final bytes = await file.readAsBytes();
        final decoded = img.decodeImage(bytes);

        if (decoded == null) {
          debugPrint("⚠️ Failed to decode image, using original.");
          return file;
        }

        final resized = img.copyResize(decoded, width: 1000);
        final compressedBytes = img.encodeJpg(resized, quality: 70);
        final compressedFile = File(targetPath)
          ..writeAsBytesSync(compressedBytes);

        final newSize = (await compressedFile.length()) / 1024;
        debugPrint("🗜️ Compressed size: ${newSize.toStringAsFixed(2)} KB ✅");
        return compressedFile;
      } else {
        // 📱 Mobile Compression using flutter_image_compress
        debugPrint("📱 Using FlutterImageCompress for mobile...");

        final result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: 70,
          minWidth: 800,
          minHeight: 800,
          format: CompressFormat.jpeg,
        );

        if (result != null) {
          final resultFile = File(result.path);
          if (await resultFile.exists()) {
            final newSize = (await resultFile.length()) / 1024;
            debugPrint("🗜️ Compressed size: ${newSize.toStringAsFixed(2)} KB ✅");
            return resultFile;
          }
        }

        debugPrint("⚠️ Compression failed, returning original.");
        return file;
      }
    } catch (e) {
      debugPrint("❌ Compression error: $e");
      return file;
    }
  }

  // 🧠 Step 3️⃣: Upload to backend for OCR extraction
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

    // Step 2️⃣ Upload and extract OCR data using existing LabTest ID
    final ocrData = await _service.uploadAndExtractOCR(
        compressedImage, widget.labTestId);

    if (!mounted) return;

    setState(() => _status = "✅ Extraction successful!");

      // Step 3️⃣ Navigate to Extracted Data Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ExtractedDataScreen(
            labTestId: widget.labTestId,
            ocrData: ocrData,
          ),
        ),
      );
    } catch (e) {
      setState(() => _status = "❌ Extraction failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ❌ Cancel button action
  void _onCancel() {
    Navigator.pop(context);
  }

  // 🧱 UI STARTS HERE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📄 Scan Report"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ Show selected image if available
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _selectedImage!,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            // 🧾 Status Text
            Text(
              _status,
              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 📸 Capture or Upload Button
            _buildButton("📷 Capture / Upload", Colors.blue, _pickImage),

            // 🧠 Extract Data Button
            _buildButton("🧠 Extract Data", Colors.green, _extractData,
                disabled: _loading),

            // ❌ Cancel Button
            _buildButton("❌ Cancel", Colors.red, _onCancel),

            // ⏳ Loader (only when uploading)
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

  // 🎨 Step 4️⃣: Reusable button widget
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
