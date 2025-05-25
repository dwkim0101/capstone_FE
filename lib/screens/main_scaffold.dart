import 'package:flutter/material.dart';
import '../widgets/smart_air_bottom_nav_bar.dart';
import 'home_tab.dart';
import 'device_tab.dart';
import 'stats_tab.dart';
import 'mypage_tab.dart';
import 'room_tab.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    DeviceTab(),
    RoomTab(),
    StatsTab(),
    MyPageTab(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SmartAirBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
