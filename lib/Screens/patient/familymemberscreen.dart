import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthcare/config_/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FamilyMemberScreen extends StatefulWidget {
  const FamilyMemberScreen({super.key});

  @override
  State<FamilyMemberScreen> createState() => _FamilyMemberScreenState();
}

class _FamilyMemberScreenState extends State<FamilyMemberScreen> {
  final picker = ImagePicker();

  List<dynamic> associates = [];

  String fullName = '';
  String dob = '';
  String gender = '';
  String relationType = '';
  String? profileImageUrl;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    loadAssociates();
  }

  // 🔹 Load family members
  Future<void> loadAssociates() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryId = prefs.getString('userId');
    final cookie = prefs.getString('session_cookie');

    if (primaryId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/associate/list/$primaryId'),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
      );

      if (response.statusCode == 200) {
        final associations = jsonDecode(response.body);
        List<dynamic> detailed = [];

        for (var assoc in associations) {
          final patientRes = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/patient/${assoc['patientId']}'),
            headers: {
              if (cookie != null) 'Cookie': cookie,
            },
          );

          if (patientRes.statusCode == 200) {
            final patient = jsonDecode(patientRes.body);
            detailed.add({
              'patientId': assoc['patientId'],
              'relationType': assoc['relationType'],
              'fullName': patient['fullName'],
              'dob': patient['dob'],
              'profileImageUrl': patient['profileImageUrl'],
            });
          }
        }

        setState(() => associates = detailed);
      }
    } catch (e) {
      print("❌ Error loading family members: $e");
    }
  }

  // 🔹 Image Picker + Upload
  Future<void> pickImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => selectedImage = File(image.path));

    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('session_cookie');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/upload/image'),
    );

    if (cookie != null) {
      request.headers['Cookie'] = cookie;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', image.path),
    );

    final response = await request.send();
    final res = await response.stream.bytesToString();
    final data = jsonDecode(res);

    setState(() => profileImageUrl = data['imageUrl']);
  }

  // 🔹 Add Family Member
  Future<void> addAssociate() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryId = prefs.getString('userId');
    final cookie = prefs.getString('session_cookie');

    if (primaryId == null ||
        fullName.isEmpty ||
        dob.isEmpty ||
        gender.isEmpty ||
        relationType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    final payload = {
      'fullName': fullName,
      'dob': dob,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
    };

    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/associate/add?primaryPatientId=$primaryId&relationType=$relationType',
        ),
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'Cookie': cookie,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        loadAssociates();
        resetForm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family member added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // 🔹 Switch Profile
  // 🔹 Switch Profile
void switchProfile(int patientId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('activePatientId', patientId.toString());

  // Return true to indicate a switch happened
  Navigator.pop(context, true);
}


  void resetForm() {
    setState(() {
      fullName = '';
      dob = '';
      gender = '';
      relationType = '';
      profileImageUrl = null;
      selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Member'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : (profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : const AssetImage('assets/icons/galleryicon.jpg')
                              as ImageProvider),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: pickImage,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: const InputDecoration(labelText: 'Full Name'),
              onChanged: (v) => fullName = v,
            ),

            const SizedBox(height: 10),

            TextField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(text: dob),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null) {
                  setState(() {
                    dob =
                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  });
                }
              },
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Radio<String>(
                  value: 'Male',
                  groupValue: gender,
                  onChanged: (v) => setState(() => gender = v!),
                ),
                const Text('Male'),
                Radio<String>(
                  value: 'Female',
                  groupValue: gender,
                  onChanged: (v) => setState(() => gender = v!),
                ),
                const Text('Female'),
              ],
            ),

            DropdownButtonFormField<String>(
              value: relationType.isEmpty ? null : relationType,
              hint: const Text('Select Relation'),
              items: const [
                'Father',
                'Mother',
                'Brother',
                'Sister',
                'Spouse',
                'Child',
                'Other'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => relationType = v!,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addAssociate,
              child: const Text('Save'),
            ),

            const SizedBox(height: 30),

            const Text(
              'Your Family Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...associates.map((m) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: m['profileImageUrl'] != null
                          ? NetworkImage(m['profileImageUrl'])
                          : const AssetImage(
                                  'assets/icons/galleryicon.jpg')
                              as ImageProvider,
                    ),
                    title: Text(m['fullName']),
                    subtitle: Text('${m['relationType']} • ${m['dob']}'),
                    trailing: TextButton(
                      onPressed: () => switchProfile(m['patientId']),
                      child: const Text('Switch'),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
