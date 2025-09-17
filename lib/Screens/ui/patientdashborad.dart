import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: PatientDashboard(),
    debugShowCheckedModeBanner: false,
  ));
}

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar-like top container
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.lightBlue,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/profile.jpg'), // Replace with your asset
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Welcome John!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Middle content (can add more here)
            const Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleIconButton(icon: Icons.folder_copy),
                    SizedBox(width: 30),
                    CircleIconButton(icon: Icons.science),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.lightBlue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'PHR'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Doctor'),
        ],
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;

  const CircleIconButton({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.lightBlue,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: () {},
      ),
    );
  }
}
