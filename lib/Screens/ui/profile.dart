import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/doctor/ui/doctordashboard.dart';
import 'package:healthcare/Screens/ui/patientdashborad.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String role; // 👈 role receive karega (Doctor ya Patient)

  const ProfilePage({super.key, required this.role});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _image;
  File? selectedImage;
  String gender = 'Male';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController(); // Doctor ke liye

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
                            backgroundImage: NetworkImage(
                              "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png",
                            ),
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

              //  Sirf Doctor ke liye Extra Field
              if (widget.role == "Doctor") ...[
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
                  onPressed: () {
                    print("Name: ${nameController.text}");
                    print("Email: ${emailController.text}");
                    print("Contact: ${contactController.text}");
                    print("Gender: $gender");

                    if (widget.role == "Doctor") {
                      print(
                          "Specialization: ${specializationController.text}");
                      // 👉 Doctor ke liye DoctorDashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DoctorDashboard()),
                      );
                    } else {
                      // 👉 Patient ke liye PatientDashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Patientdashborad()),
                      );
                    }
                  },
                  child: const Text(
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
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }

  // Pick from camera
  Future _pickImageFromCamera() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnImage == null) return;
    setState(() {
      selectedImage = File(returnImage.path);
      _image = File(returnImage.path).readAsBytesSync();
    });
    Navigator.of(context).pop();
  }
}
