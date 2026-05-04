import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';

// KMUTT design tokens — kept local to this screen until the rest of the app
// migrates off the cool grey palette.
class _Tokens {
  static const bg = Color(0xFFFBF7EC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6DDC4);
  static const borderStrong = Color(0xFFCBBF9F);

  static const ink900 = Color(0xFF1B1610);
  static const ink800 = Color(0xFF2A241B);
  static const ink700 = Color(0xFF423A2D);
  static const ink600 = Color(0xFF5C5242);
  static const ink500 = Color(0xFF7A6F5B);
  static const ink400 = Color(0xFF9C9179);
  static const ink200 = Color(0xFFE2DAC1);
  static const ink100 = Color(0xFFF1EBD8);

  static const primary50 = Color(0xFFFFF8E9);
  static const primary300 = Color(0xFFF7C264);
  static const primary500 = Color(0xFFD98A0E);
  static const primary700 = Color(0xFF8A5103);
  static const primary800 = Color(0xFF5C3601);

  static const success = Color(0xFF2F7D3E);
  static const successBg = Color(0xFFE4F2DD);
  static const danger = Color(0xFFB23A28);
  static const dangerBg = Color(0xFFFBE3DD);
  static const info = Color(0xFF2A5D8F);
  static const infoBg = Color(0xFFE0ECF5);
  static const warn = Color(0xFFA96C00);
  static const warnBg = Color(0xFFFCECC3);
}

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
        backgroundColor: _Tokens.bg,
        appBar: AppBar(
          backgroundColor: _Tokens.bg,
          elevation: 0,
          title: const Text('Request not found'),
        ),
        body: const Center(
          child: Text(
            'This request is no longer available.',
            style: TextStyle(color: _Tokens.ink600),
          ),
        ),
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

    final allRequests = isPoster
        ? (ref.watch(watchRequestsForItemProvider(item.id)).valueOrNull ?? [])
        : <ItemRequest>[];
    final otherPendingCount = allRequests
        .where((r) => r.status == RequestStatus.pending && r.id != req.id)
        .length;

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
      backgroundColor: _Tokens.bg,
      appBar: AppBar(
        backgroundColor: _Tokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: _Tokens.border, width: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request detail'),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: _Tokens.ink500,
              ),
              overflow: TextOverflow.ellipsis,
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
            _MessageCard(req: req),
            const SizedBox(height: 14),
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
                    child: _PillButton(
                      label: 'Reject',
                      kind: _PillKind.danger,
                      onPressed: actionState.isLoading
                          ? null
                          : () => _reject(context, ref),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PillButton(
                      label: 'Approve',
                      kind: _PillKind.primary,
                      onPressed: actionState.isLoading
                          ? null
                          : () => _approve(context, ref, otherPendingCount),
                    ),
                  ),
                ],
              ),
            ],
            if (isMyRequest && req.status == RequestStatus.pending) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _PillButton(
                  label: 'Cancel my request',
                  kind: _PillKind.secondary,
                  onPressed: actionState.isLoading
                      ? null
                      : () => _cancel(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, int otherPendingCount) async {
    final typeLabel =
        req.type == RequestType.found ? 'found report' : 'claim';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Tokens.surface,
        title: Text("Approve ${req.requesterName}'s $typeLabel?"),
        content: _ApproveDialogBody(
          itemTitle: item.title,
          requesterName: req.requesterName,
          otherPendingCount: otherPendingCount,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _Tokens.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
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
    final typeLabel =
        req.type == RequestType.found ? 'found report' : 'claim';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Tokens.surface,
        title: Text("Reject ${req.requesterName}'s $typeLabel?"),
        content: _RejectDialogBody(requesterName: req.requesterName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _Tokens.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Tokens.surface,
        title: const Text('Cancel your request?'),
        content: const Text(
          "The poster will see this request as cancelled and won't be able to approve it. "
          'You can submit a new request later if needed.',
          style: TextStyle(color: _Tokens.ink700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _Tokens.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
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

// ─── Pill button (matches lf-btn) ────────────────────────────────────────────

enum _PillKind { primary, danger, secondary }

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.kind,
    required this.onPressed,
  });

  final String label;
  final _PillKind kind;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );
    const padding = EdgeInsets.symmetric(vertical: 13, horizontal: 18);
    final textStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.01,
    );

    switch (kind) {
      case _PillKind.primary:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _Tokens.primary500,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _Tokens.ink200,
            elevation: 0,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          ),
          onPressed: onPressed,
          child: Text(label),
        );
      case _PillKind.danger:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: _Tokens.danger,
            side: BorderSide(
              color: disabled ? _Tokens.ink200 : _Tokens.danger,
              width: 1.5,
            ),
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          ),
          onPressed: onPressed,
          child: Text(label),
        );
      case _PillKind.secondary:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: _Tokens.surface,
            foregroundColor: _Tokens.ink900,
            side: const BorderSide(color: _Tokens.borderStrong, width: 1.5),
            padding: padding,
            shape: shape,
            textStyle: textStyle,
          ),
          onPressed: onPressed,
          child: Text(label),
        );
    }
  }
}

// ─── Section label (matches lf-label) ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.02 * 12.5, // 0.02em
        color: _Tokens.ink700,
      ),
    );
  }
}

// ─── Status row ──────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.req});

  final ItemRequest req;

  @override
  Widget build(BuildContext context) {
    final isClaimType = req.type == RequestType.claim;
    final (Color typeColor, Color typeBg) = isClaimType
        ? (_Tokens.primary700, _Tokens.primary50)
        : (_Tokens.info, _Tokens.infoBg);

    return Row(
      children: [
        _statusChip(req.status),
        const SizedBox(width: 8),
        Text(
          _relativeTime(req.createdAt),
          style: const TextStyle(fontSize: 12.5, color: _Tokens.ink500),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: isClaimType ? 'Claim Request' : 'Found Report',
          color: typeColor,
          background: typeBg,
        ),
      ],
    );
  }

  Widget _statusChip(RequestStatus status) {
    final (Color color, Color bg) = switch (status) {
      RequestStatus.pending => (_Tokens.warn, _Tokens.warnBg),
      RequestStatus.approved => (_Tokens.success, _Tokens.successBg),
      RequestStatus.rejected => (_Tokens.danger, _Tokens.dangerBg),
      RequestStatus.cancelled => (_Tokens.ink600, _Tokens.ink200),
    };
    return _Chip(label: status.name, color: color, background: bg);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.04 * 11, // 0.04em
        ),
      ),
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.child,
    this.background = _Tokens.surface,
    this.borderColor = _Tokens.border,
  });

  final Widget child;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F3C2A0A),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _RequesterCard extends StatelessWidget {
  const _RequesterCard({required this.req});

  final ItemRequest req;

  @override
  Widget build(BuildContext context) {
    return _DesignCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _Tokens.ink100,
            child: Text(
              req.requesterName.isNotEmpty
                  ? req.requesterName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: _Tokens.ink600,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.requesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _Tokens.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID ${req.studentId} · ${req.requesterContact}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _Tokens.ink500,
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.req});

  final ItemRequest req;

  @override
  Widget build(BuildContext context) {
    final isFound = req.type == RequestType.found;
    final hasMessage = req.message != null && req.message!.trim().isNotEmpty;

    return _DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            isFound
                ? "Requester's description of the item"
                : 'Message from requester',
          ),
          const SizedBox(height: 8),
          if (hasMessage)
            Text(
              req.message!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: _Tokens.ink800,
              ),
            )
          else
            Text(
              isFound
                  ? 'No description provided. Ask the requester for distinctive details before approving.'
                  : "No message left. The requester didn't add extra context — verify their identity carefully.",
              style: const TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: _Tokens.ink400,
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
                    Container(height: 200, color: _Tokens.ink100),
              ),
            ),
          ],
        ],
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
    return _DesignCard(
      background: _Tokens.primary50,
      borderColor: _Tokens.primary300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: _Tokens.primary700),
              SizedBox(width: 6),
              Text(
                'VERIFICATION',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _Tokens.primary800,
                  letterSpacing: 0.04 * 13,
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
                  valueColor: _Tokens.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _verifyCell(
            label: "Visitor's answer",
            value: req.visitorAnswer ?? 'No answer provided',
            valueColor: req.visitorAnswer != null
                ? _Tokens.ink900
                : _Tokens.ink400,
            bold: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'ⓘ Comparison is manual — you decide if the answers match before approving.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _Tokens.ink500,
              height: 1.45,
            ),
          ),
        ],
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
        color: _Tokens.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: _Tokens.ink500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? _Tokens.ink900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialogs ─────────────────────────────────────────────────────────────────

class _ApproveDialogBody extends StatelessWidget {
  const _ApproveDialogBody({
    required this.itemTitle,
    required this.requesterName,
    required this.otherPendingCount,
  });

  final String itemTitle;
  final String requesterName;
  final int otherPendingCount;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 14,
      color: _Tokens.ink700,
      height: 1.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Once approved:', style: baseStyle),
        const SizedBox(height: 8),
        _Bullet(child: RichText(
          text: TextSpan(
            style: baseStyle,
            children: [
              const TextSpan(text: 'Your post '),
              TextSpan(text: '"$itemTitle"', style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' will be marked '),
              const TextSpan(text: 'resolved', style: TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' and removed from the public feed.'),
            ],
          ),
        )),
        if (otherPendingCount > 0)
          _Bullet(child: RichText(
            text: TextSpan(
              style: baseStyle,
              children: [
                TextSpan(
                  text: '$otherPendingCount other pending request${otherPendingCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' on this post will be automatically rejected.'),
              ],
            ),
          )),
        _Bullet(child: Text(
          '$requesterName will be notified to contact you and arrange a handover.',
          style: baseStyle,
        )),
        _Bullet(child: RichText(
          text: const TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: 'This action '),
              TextSpan(text: 'cannot be undone', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' from the app.'),
            ],
          ),
        )),
        const SizedBox(height: 10),
        const Text(
          "Make sure you've verified the requester's identity before approving.",
          style: TextStyle(fontSize: 13, color: _Tokens.ink500, height: 1.45),
        ),
      ],
    );
  }
}

class _RejectDialogBody extends StatelessWidget {
  const _RejectDialogBody({required this.requesterName});

  final String requesterName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$requesterName will be notified that their request was declined. '
          'Your post stays open and other people can still submit requests.',
          style: const TextStyle(fontSize: 14, color: _Tokens.ink700, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'The requester may submit again with more detail.',
          style: TextStyle(fontSize: 13, color: _Tokens.ink500, height: 1.45),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 8),
            child: SizedBox(
              width: 5,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _Tokens.ink600,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(child: child),
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
