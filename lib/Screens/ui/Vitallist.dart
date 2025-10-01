import 'package:flutter/material.dart';
import 'package:healthcare/Screens/ui/addvitals.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
class VitalHomeScreen extends StatefulWidget {
  const VitalHomeScreen({super.key});

  @override
  State<VitalHomeScreen> createState() => _VitalHomeScreenState();
}

class _VitalHomeScreenState extends State<VitalHomeScreen> {
  String filter = "ALL";
  List<Map<String, dynamic>> vitals = [];

  Future<void> _openAddVitalDialog({Map<String, dynamic>? existing, int? index}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddVitalDialog(existingVital: existing),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          vitals[index] = result;
        } else {
          vitals.add(result);
        }
      });
    }
  }

  List<Map<String, dynamic>> get filteredVitals {
    if (filter == "ALL") return vitals;
    return vitals.where((v) => v['type'] == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Vital Sign', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _openAddVitalDialog(),
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            label: const Text("Add Vital", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton("ALL"),
              _buildFilterButton("BP"),
              _buildFilterButton("Pulse"),
              _buildFilterButton("Temp"),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredVitals.isEmpty
                ? const Center(child: Text("No Vitals Added Yet"))
                : ListView.builder(
                    itemCount: filteredVitals.length,
                    itemBuilder: (context, index) {
                      final v = filteredVitals[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            v['type'] == 'BP'
                                ? "BP"
                                : v['type'] == 'Pulse'
                                    ? "Pulse Rate"
                                    : "Temperature",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${v['display']}\n${v['datetime']}"),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _openAddVitalDialog(existing: v, index: index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    vitals.remove(v);
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
    );
  }

  Widget _buildFilterButton(String type) {
    final bool isSelected = filter == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(
          type == "BP"
              ? "BP"
              : type == "Temp"
                  ? "Temperature"
                  : type == "Pulse"
                      ? "Pulse Rate"
                      : "ALL",
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => filter = type),
        selectedColor: Colors.deepPurple[100],
      ),
    );
  }
}
