import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/doctor/ui/doctordashboard.dart';
import 'package:healthcare/Screens/ui/patientdashborad.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:healthcare/Screens/ui/config/api_config.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  final String userId;

  const ProfilePage({super.key, required this.role, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _image;
  File? selectedImage;
  String gender = 'Male';
  DateTime? selectedDob;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool _isLoading = false;

  //  Save Profile
  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final contact = contactController.text.trim();
    final specialization = specializationController.text.trim();

    if (name.isEmpty || email.isEmpty || contact.isEmpty || selectedDob == null) {
      _showSnackBar("Please fill all required fields ❌");
      return;
    }

    setState(() => _isLoading = true);

    String apiUrl = "";
    if (widget.role.toUpperCase() == "PATIENT") {
      apiUrl = "${ApiConfig.baseUrl}/patient/add?userId=${widget.userId}";
    } else if (widget.role.toUpperCase() == "DOCTOR") {
      apiUrl = "${ApiConfig.baseUrl}/doctor/add?userId=${widget.userId}";
    } else {
      _showSnackBar("Unknown role ");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cookie = prefs.getString("session_cookie");

      // Step 1: Upload Image
      String? uploadedImageUrl;
      if (selectedImage != null) {
        var uploadReq = http.MultipartRequest(
          "POST",
          Uri.parse("${ApiConfig.baseUrl}/uploads/images"),
        );
        uploadReq.files.add(await http.MultipartFile.fromPath("file", selectedImage!.path));
        if (cookie != null) uploadReq.headers["Cookie"] = cookie;

        var uploadRes = await uploadReq.send();
        if (uploadRes.statusCode == 200) {
          final respStr = await uploadRes.stream.bytesToString();
          final jsonResp = jsonDecode(respStr);
          uploadedImageUrl = jsonResp["imageUrl"];
          print(" Image uploaded: $uploadedImageUrl");
        } else {
          _showSnackBar("Image upload failed ");
          setState(() => _isLoading = false);
          return;
        }
      }

      // Step 2: Prepare JSON body
      String formattedDob = DateFormat('yyyy-MM-dd').format(selectedDob!);

      final body = {
        "fullName": name,
        "email": email,
        "contact": contact,
        "gender": gender,
        "dob": formattedDob,
        if (widget.role.toUpperCase() == "DOCTOR") "specialization": specialization,
        if (uploadedImageUrl != null) "profileImageUrl": uploadedImageUrl,
      };

      print(" Sending Payload: $body");

      // Step 3: Send profile data
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          if (cookie != null) "Cookie": cookie,
        },
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(" Profile saved: ${response.body}");
        _showSnackBar("Profile saved successfully ", isSuccess: true);

        Future.delayed(const Duration(seconds: 1), () {
          if (widget.role.toUpperCase() == "PATIENT") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Patientdashborad()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DoctorDashboard()),
            );
          }
        });
      } else {
        print(" Failed response: ${response.body}");
        _showSnackBar("Failed to save profile : ${response.body}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print(" Error: $e");
      _showSnackBar("Error: $e");
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _pickDob() async {
    DateTime initialDate = DateTime(2000, 1, 1);
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        selectedDob = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF53B2E8), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 30),

              // Profile Image
              Center(
                child: Stack(
                  children: [
                    _image != null
                        ? CircleAvatar(
                            radius: 80,
                            backgroundImage: MemoryImage(_image!),
                          )
                        : const CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 80, color: Colors.white),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        onPressed: () {
                          showImagePickerOption(context);
                        },
                        icon: const Icon(Icons.add_a_photo, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Fields
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Enter Name',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Enter Email',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Enter Contact',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // DOB Picker
              TextField(
                controller: dobController,
                readOnly: true,
                onTap: _pickDob,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'Select Date of Birth',
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Doctor only field
              if (widget.role.toUpperCase() == "DOCTOR") ...[
                TextField(
                  controller: specializationController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.work),
                    hintText: 'Enter Specialization',
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Gender selection
              Row(
                children: [
                  const Text("Gender:  "),
                  Radio(
                    value: 'Male',
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() {
                        gender = value!;
                      });
                    },
                  ),
                  const Text("Male"),
                  Radio(
                    value: 'Female',
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() {
                        gender = value!;
                      });
                    },
                  ),
                  const Text("Female"),
                ],
              ),
              const SizedBox(height: 30),

              // Save Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.blue],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Image Picker Bottom Sheet
  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.blue[100],
      context: context,
      builder: (builder) {
        return Padding(
          padding: const EdgeInsets.all(18.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height / 4.5,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickImageFromGallery();
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 70),
                        Text("Gallery"),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _pickImageFromCamera();
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 70),
                        Text("Camera"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Pick from gallery
  Future _pickImageFromGallery() async {
    final returnImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }

  // Pick from camera
  Future _pickImageFromCamera() async {
    final returnImage = await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }
}
