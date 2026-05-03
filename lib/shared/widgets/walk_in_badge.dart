import 'package:flutter/material.dart';

class WalkInBadge extends StatelessWidget {
  const WalkInBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'QR WALK-IN',
        style: TextStyle(
          color: Color(0xFF3B5BDB),
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
