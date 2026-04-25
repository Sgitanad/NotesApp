
import 'package:flutter/material.dart';
import 'pages/page1.dart'; // Import Page1
import 'pages/page2.dart'; // Import Page2
import 'pages/page3.dart'; // Import Page3
import 'pages/page4.dart'; // Import Page4

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOTES',
          style: TextStyle(
            color: Color(0xFFEAE0CF), 
            fontSize: 50, 
            fontWeight: FontWeight.bold, 
          ),
        ),
        backgroundColor: const Color(0xFF213448),
        toolbarHeight: 110,
      ),
      backgroundColor: const Color(0xFFEAE0CF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First row: Add Notes & Show Notes
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuButton(
                  icon: Icons.add_circle_outline,
                  text: 'Add Notes',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Page1())),
                ),
                const SizedBox(width: 40),
                _buildMenuButton(
                  icon: Icons.list_alt,
                  text: 'Show Notes',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Page2())),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Second row: Modify Notes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuButton(
                  icon: Icons.edit_note,
                  text: 'Modify Notes',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Page3())),
                ),
                const SizedBox(width: 40),
                _buildMenuButton(
                  icon: Icons.delete_outline,
                  text: 'Delete Notes',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Page4())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 160,
      height: 160,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF547792),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: const Color(0xFFEAE0CF),
            ),
            const SizedBox(height: 15),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFFEAE0CF), 
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

