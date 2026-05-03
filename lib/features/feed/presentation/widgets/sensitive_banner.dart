import 'package:flutter/material.dart';

class SensitiveBanner extends StatelessWidget {
  const SensitiveBanner({super.key, required this.securityPhone});

  final String securityPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sensitive item — cannot be claimed through the app',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This item (ID card, bank card, passport or similar document) must be '
                  'collected in person from the Security Office with valid identification.',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Contact Security Office · $securityPhone',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
