import 'package:flutter/material.dart';

class AddVitalScreen extends StatefulWidget {
  const AddVitalScreen({super.key});

  @override
  State<AddVitalScreen> createState() => _AddVitalScreenState();
}

class _AddVitalScreenState extends State<AddVitalScreen> {
  String selectedVital = "Temperature"; 
  String selectedType = ""; 
  TextEditingController valueController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final Map<String, List<String>> vitalTypes = {
    "Temperature": ["Celsius", "Fahrenheit"],
    "Blood Pressure": ["Systolic", "Diastolic"],
    "Pulse Rate": ["Resting", "Active"],
  };

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedType.isEmpty && vitalTypes[selectedVital]!.isNotEmpty) {
      selectedType = vitalTypes[selectedVital]!.first;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text("PHR",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text("Add New Vital Sign",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.blue),
                  ),
                ],
              ),
            ),

            // Main card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Select Type",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: selectedVital,
                            items: vitalTypes.keys.map((String vital) {
                              return DropdownMenuItem<String>(
                                value: vital,
                                child: Text(vital),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedVital = value!;
                                selectedType = vitalTypes[selectedVital]!.first;
                              });
                            },
                          ),
                        ],
                      ),

                      // Radio buttons
                      Row(
                        children: vitalTypes[selectedVital]!
                            .map((type) => Row(
                                  children: [
                                    Radio<String>(
                                      value: type,
                                      groupValue: selectedType,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedType = value!;
                                        });
                                      },
                                    ),
                                    Text(type),
                                    const SizedBox(width: 10),
                                  ],
                                ))
                            .toList(),
                      ),

                      // Value input
                      TextField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Enter Value Here",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date & Time
                      GestureDetector(
                        onTap: () async {
                          await _pickDate();
                          await _pickTime();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${selectedDate.month}/${selectedDate.day}/${selectedDate.year}"),
                                  Text(selectedTime.format(context)),
                                ],
                              ),
                              const Icon(Icons.edit, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    // 👇 yahan data banake wapas bhejna
                    final newVital = {
                      "type": selectedVital,
                      "value": "${valueController.text} ($selectedType)",
                      "date":
                          "${selectedDate.month}/${selectedDate.day}/${selectedDate.year}",
                      "time": selectedTime.format(context),
                    };
                    Navigator.pop(context, newVital);
                  },
                  child: const Text("Save"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
