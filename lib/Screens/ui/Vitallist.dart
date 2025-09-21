import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/patientdashborad.dart';
import 'addvitals.dart';


class VitalListScreen extends StatefulWidget {
  const VitalListScreen({super.key});

  @override
  State<VitalListScreen> createState() => _VitalListScreenState();
}

class _VitalListScreenState extends State<VitalListScreen> {
  String selectedFilter = "ALL";
  int myIndex = 1; // 👈 default PHR tab selected

  final List<Map<String, String>> vitals = [
    {"type": "BP", "value": "89 / 120", "date": "Dec 5, 2023", "time": "10:00 AM"},
    {"type": "Pulse Rate", "value": "72 bpm", "date": "May 21, 2023", "time": "3:00 AM"},
    {"type": "BP", "value": "110 / 80", "date": "Oct 5, 2023", "time": "5:00 AM"},
    {"type": "Temp", "value": "102°F", "date": "Jul 5, 2023", "time": "1:00 AM"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text("PHR", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text("Vital Sign", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddVitalScreen(),
                        ),
                      );

                      if (result != null && result is Map<String, String>) {
                        setState(() {
                          vitals.add(result);
                        });
                      }
                    },
                    child: Row(
                      children: const [
                        Text("Add Vital",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500)),
                        SizedBox(width: 6),
                        Icon(Icons.add_circle, color: Colors.blue, size: 26),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // ✅ Filter buttons
            Row(
              children: ["ALL", "BP", "Pulse Rate", "Temperature"]
                  .map((filter) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selectedFilter == filter,
                          onSelected: (val) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),

            // ✅ Vitals list
            Expanded(
              child: ListView.builder(
                itemCount: vitals.length,
                itemBuilder: (context, index) {
                  final vital = vitals[index];
                  if (selectedFilter != "ALL" &&
                      vital["type"] != selectedFilter) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Text(
                        vital["type"]!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      title: Text(vital["value"]!),
                      subtitle: Text("${vital["date"]} • ${vital["time"]}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Edit clicked")),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                vitals.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ✅ Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightBlue,
        showSelectedLabels: false,
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>  Patientdashborad()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'Vitals'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Doctor'),
        ],
      ),
    );
  }
}

// ✅ Main app start
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VitalListScreen(),
    );
  }
}
