import 'package:flutter/material.dart';
import '../Pages/Dashboard.dart';
import '../Pages/PatientDetails.dart';
import '../Pages/History.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF04101A),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return; // Do nothing if tapping the same tab
          
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PatientDetails()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const History()),
            );
          }
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF45DFB1), // Green highlight
        unselectedItemColor: Colors.grey.shade500,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: width * 0.03,
        unselectedFontSize: width * 0.03,
        items: [
          _buildNavigationBarItem(Icons.home_filled, Icons.home_filled, 'Home', width, currentIndex == 0),
          _buildNavigationBarItem(Icons.crop_free, Icons.crop_free, 'Scan', width, currentIndex == 1),
          _buildNavigationBarItem(Icons.assignment_outlined, Icons.assignment, 'History', width, currentIndex == 2),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      IconData icon, IconData activeIcon, String label, double width, bool isSelected) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(bottom: width * 0.01),
        child: Icon(icon, size: width * 0.06),
      ),
      activeIcon: Padding(
        padding: EdgeInsets.only(bottom: width * 0.01),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF45DFB1).withOpacity(0.2),
            borderRadius: BorderRadius.circular(width * 0.03),
          ),
          padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.015),
          child: Icon(activeIcon, size: width * 0.06),
        ),
      ),
      label: label,
    );
  }
}
