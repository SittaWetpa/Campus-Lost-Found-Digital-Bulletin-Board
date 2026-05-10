import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';

class CooldownCountdown extends ConsumerWidget {
  const CooldownCountdown({
    super.key,
    required this.retryAfter,
    required this.itemId,
    required this.requesterId,
  });

  final DateTime retryAfter;
  final String itemId;
  final String requesterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAsync = ref.watch(cooldownRemainingProvider(retryAfter));
    final remaining = remainingAsync.valueOrNull ??
        retryAfter.difference(DateTime.now());

    if (remaining.isNegative || remaining == Duration.zero) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(resubmitDecisionProvider(itemId, requesterId));
      });
      return const SizedBox.shrink();
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can submit a new request in ${hours}h ${minutes}m',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
