import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({
    super.key,
    required this.itemId,
    required this.reqId,
  });

  final String itemId;
  final String reqId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(watchItemProvider(itemId));
    final reqAsync  = ref.watch(watchSingleRequestProvider(itemId, reqId));

    final item = itemAsync.valueOrNull;
    final req  = reqAsync.valueOrNull;

    if (itemAsync.isLoading || reqAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (item == null || req == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request detail')),
        body: const Center(child: Text('Request not found.')),
      );
    }

    return _RequestDetailView(item: item, req: req);
  }
}

class _RequestDetailView extends ConsumerWidget {
  const _RequestDetailView({required this.item, required this.req});

  final Item item;
  final ItemRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final flags = ref.watch(featureFlagsProvider);
    final isPoster = item.userId == authUser?.uid;
    final isMyRequest = req.requesterId == authUser?.uid;
    final actionState = ref.watch(itemDetailActionNotifierProvider);

    // Fetch secretAnswer from the private sub-document (poster-only access).
    // Falls back to item.secretAnswer for legacy items not yet migrated to
    // the private sub-document.
    final privateSecretAsync =
        isPoster && item.secretQuestion != null && flags.secretQuestionEnabled
            ? ref.watch(getItemSecretAnswerProvider(item.id))
            : const AsyncData<String?>(null);
    final effectiveSecretAnswer =
        privateSecretAsync.valueOrNull ?? item.secretAnswer;

    ref.listen(itemDetailActionNotifierProvider, (_, state) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Action failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE0),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request detail'),
            Text(
              item.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(req: req),
            const SizedBox(height: 14),
            _RequesterCard(req: req),
            const SizedBox(height: 14),
            if (req.message != null) ...[
              _MessageCard(req: req),
              const SizedBox(height: 14),
            ],
            if (isPoster &&
                req.type == RequestType.claim &&
                item.secretQuestion != null &&
                flags.secretQuestionEnabled) ...[
              _VerificationCard(
                item: item,
                req: req,
                secretAnswer: effectiveSecretAnswer,
              ),
              const SizedBox(height: 14),
            ],
            if (isPoster && req.status == RequestStatus.pending) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _reject(context, ref),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCA8A04),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: actionState.isLoading
                          ? null
                          : () => _approve(context, ref),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (isMyRequest && req.status == RequestStatus.pending) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: actionState.isLoading
                      ? null
                      : () => _cancel(context, ref),
                  child: const Text('Cancel my request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(itemDetailActionNotifierProvider.notifier).approve(
          itemId: item.id,
          requestId: req.id,
          requesterId: req.requesterId,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved — post resolved')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(itemDetailActionNotifierProvider.notifier).reject(
          itemId: item.id,
          requestId: req.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    await ref.read(itemDetailActionNotifierProvider.notifier).cancel(
          itemId: item.id,
          requestId: req.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
      Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.req});

  final ItemRequest req;

  @override
  Widget build(BuildContext context) {
    final isClaimType = req.type == RequestType.claim;
    final (Color typeColor, Color typeBg) = isClaimType
        ? (const Color(0xFF3B82F6), const Color(0xFFEFF6FF))
        : (const Color(0xFF0891B2), const Color(0xFFECFEFF));

    return Row(
      children: [
        _statusChip(req.status),
        const SizedBox(width: 8),
        Text(
          _relativeTime(req.createdAt),
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: typeBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isClaimType ? 'Claim Request' : 'Found Report',
            style: TextStyle(
              color: typeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(RequestStatus status) {
    final (Color color, Color bg) = switch (status) {
      RequestStatus.pending =>
        (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      RequestStatus.approved =>
        (const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      RequestStatus.rejected =>
        (const Color(0xFFDC2626), const Color(0xFFFFE4E6)),
      RequestStatus.cancelled =>
        (const Color(0xFF6B7280), const Color(0xFFF3F4F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequesterCard extends StatelessWidget {
  const _RequesterCard({required this.req});

  final ItemRequest req;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE5E7EB),
              child: Text(
                req.requesterName.isNotEmpty
                    ? req.requesterName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.requesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'ID ${req.studentId} · ${req.requesterContact}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.req});

  final ItemRequest req;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              req.type == RequestType.found
                  ? 'Description of found item'
                  : 'Message',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              req.message!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Color(0xFF374151),
              ),
            ),
            if (req.photoUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  req.photoUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 200, color: const Color(0xFFE5E7EB)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.item,
    required this.req,
    required this.secretAnswer,
  });

  final Item item;
  final ItemRequest req;
  final String? secretAnswer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF93C5FD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: Color(0xFF1D4ED8)),
                SizedBox(width: 6),
                Text(
                  'VERIFICATION',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _verifyCell(
                    label: 'Your secret question',
                    value: '"${item.secretQuestion!}"',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _verifyCell(
                    label: 'Your expected answer',
                    value: secretAnswer ?? '—',
                    valueColor: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _verifyCell(
              label: "Visitor's answer",
              value: req.visitorAnswer ?? 'No answer provided',
              valueColor: req.visitorAnswer != null
                  ? const Color(0xFF111827)
                  : const Color(0xFF9CA3AF),
              bold: true,
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠ Comparison is manual — you decide if the answers match before approving.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifyCell({
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
