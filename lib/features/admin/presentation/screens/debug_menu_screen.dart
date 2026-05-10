import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:campus_lost_found/core/observability/app_logger.dart';

const _kAmber  = Color(0xFFD98A0E);
const _kBg     = Color(0xFFFBF7EC);
const _kBorder = Color(0xFFE6DDC4);
const _kInk500 = Color(0xFF7A6F5B);
const _kInk900 = Color(0xFF1B1610);

class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  void _triggerFatalCrash() {
    if (!kIsWeb) FirebaseCrashlytics.instance.crash();
  }

  void _triggerNonFatalCrash() {
    AppLogger.error(
      'Test non-fatal crash triggered from debug menu',
      tag: 'DebugMenuScreen',
      error: Exception('Intentional test non-fatal'),
      stackTrace: StackTrace.current,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE0),
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Debug Menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kInk900,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'CRASHLYTICS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: _kInk500,
              ),
            ),
          ),
          _ActionCard(
            label: 'Trigger test non-fatal',
            sub: 'Records a non-fatal error via AppLogger.error()',
            onTap: () {
              _triggerNonFatalCrash();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Non-fatal error sent to Crashlytics (release only)'),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _ActionCard(
            label: 'Trigger fatal crash',
            sub: 'Calls FirebaseCrashlytics.crash() — app will terminate',
            labelColor: Colors.red.shade700,
            onTap: kIsWeb
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Trigger fatal crash?'),
                        content: const Text(
                          'The app will crash immediately. This is irreversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: _triggerFatalCrash,
                            child: Text(
                              'Crash now',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.only(top: 12, left: 4),
              child: Text(
                'Fatal crash is disabled on Web — Crashlytics is mobile-only.',
                style: TextStyle(fontSize: 12, color: _kInk500),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final String sub;
  final VoidCallback? onTap;
  final Color? labelColor;

  const _ActionCard({
    required this.label,
    required this.sub,
    this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F3C2A0A),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? _kInk900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 12, color: _kInk500),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: _kAmber),
          ],
        ),
      ),
    );
  }
}
