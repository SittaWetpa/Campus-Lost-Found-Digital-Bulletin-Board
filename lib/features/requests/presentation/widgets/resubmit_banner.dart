import 'package:flutter/material.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/presentation/widgets/cooldown_countdown.dart';

class ResubmitBanner extends StatelessWidget {
  const ResubmitBanner({
    super.key,
    required this.decision,
    required this.itemId,
    required this.requesterId,
  });

  final ResubmitDecision decision;
  final String itemId;
  final String requesterId;

  @override
  Widget build(BuildContext context) {
    switch (decision.reason) {
      case ResubmitReason.allowed:
        final remaining = decision.attemptsRemaining;
        if (remaining == null || remaining >= 3) {
          return const SizedBox.shrink();
        }
        return _Banner(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFD97706),
          background: const Color(0xFFFEF3C7),
          border: const Color(0xFFF59E0B),
          text: remaining == 1
              ? 'Incorrect answer. 1 attempt remaining.'
              : 'Incorrect answer. $remaining attempts remaining.',
        );
      case ResubmitReason.permanentBlock:
        return const _Banner(
          icon: Icons.lock_outline,
          color: Color(0xFFDC2626),
          background: Color(0xFFFFE4E6),
          border: Color(0xFFFCA5A5),
          text: 'You can no longer submit a request on this post.',
        );
      case ResubmitReason.cooldown:
        final retryAfter = decision.retryAfter;
        if (retryAfter == null) return const SizedBox.shrink();
        return CooldownCountdown(
          retryAfter: retryAfter,
          itemId: itemId,
          requesterId: requesterId,
        );
      case ResubmitReason.alreadyActive:
        return const SizedBox.shrink();
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
