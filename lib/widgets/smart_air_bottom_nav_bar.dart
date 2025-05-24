import 'package:flutter/material.dart';

class SmartAirBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const SmartAirBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(
          0xFF141417,
        ), // Solid background color matching the top gradient
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent, // Ensure transparency
        selectedItemColor: const Color(0xFF3971FF), // Highlight color
        unselectedItemColor: Colors.white.withOpacity(
          0.7,
        ), // Dimmed unselected color
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        enableFeedback: false, // Disable feedback like ripple effect
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: '기기'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
        currentIndex: selectedIndex,
        onTap: onTap,
      ),
    );
  }
}
