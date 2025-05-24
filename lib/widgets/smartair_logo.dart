import 'package:flutter/material.dart';

class SmartAirLogo extends StatelessWidget {
  const SmartAirLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFF004FFF)],
        ),
      ),
    );
  }
}
