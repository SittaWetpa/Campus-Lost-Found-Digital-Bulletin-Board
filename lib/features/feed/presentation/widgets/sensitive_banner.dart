import 'package:flutter/material.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';

class SensitiveBanner extends StatelessWidget {
  const SensitiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTokens.warnBg,
        border: Border.all(color: AppTokens.warnBorder),
        borderRadius: BorderRadius.circular(AppTokens.rMd),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sensitive item — cannot be claimed through the app',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTokens.warn,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This item (ID card, bank card, passport or similar document) must be '
                  'collected in person from the Security Office with valid identification.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTokens.ink800,
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
