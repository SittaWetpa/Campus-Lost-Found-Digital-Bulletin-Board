import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_claim_request_use_case.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/submit_request_provider.dart';

// ── Design tokens (KMUTT warm gold palette) ───────────────────────────────────
const _kBg           = Color(0xFFF9F5E8);
const _kSurface      = Colors.white;
const _kBorder       = Color(0xFFE6DDC4);
const _kPrimary      = Color(0xFFD98A0E);
const _kPrimary50    = Color(0xFFFFF8E9);
const _kPrimary400   = Color(0xFFE9A534);
const _kPrimary700   = Color(0xFF8A5103);
const _kPrimary800   = Color(0xFF5C3601);
const _kInk900       = Color(0xFF1B1610);
const _kInk800       = Color(0xFF2A241B);
const _kInk500       = Color(0xFF7A6F5B);
const _kInk400       = Color(0xFF9C9179);
const _kInk200       = Color(0xFFE2DAC1);
const _kInk100       = Color(0xFFF1EBD8);

class ClaimRequestScreen extends ConsumerStatefulWidget {
  const ClaimRequestScreen({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<ClaimRequestScreen> createState() =>
      _ClaimRequestScreenState();
}

class _ClaimRequestScreenState extends ConsumerState<ClaimRequestScreen> {
  final _messageCtrl = TextEditingController();
  final _answerCtrl  = TextEditingController();

  String? _answerError;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final item = ref.read(watchItemProvider(widget.itemId)).valueOrNull;
    final me   = ref.read(currentUserProvider).valueOrNull;
    final flags = ref.read(featureFlagsProvider);
    if (item == null || me == null) return;

    final hasSecret = item.secretQuestion != null && flags.secretQuestionEnabled;

    if (hasSecret && _answerCtrl.text.trim().isEmpty) {
      setState(() => _answerError = 'Answer is required');
      return;
    }
    setState(() => _answerError = null);

    await ref.read(submitClaimRequestProvider.notifier).submit(
          SubmitClaimRequestParams(
            itemId: widget.itemId,
            requesterId: me.uid,
            requesterName: '${me.firstName} ${me.lastName}',
            requesterContact: me.telephone,
            studentId: me.studentId,
            message: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
            visitorAnswer: _answerCtrl.text.trim().isEmpty
                ? null
                : _answerCtrl.text.trim(),
          ),
        );

    if (!mounted) return;
    final state = ref.read(submitClaimRequestProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send claim request. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim request sent')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync  = ref.watch(watchItemProvider(widget.itemId));
    final meAsync    = ref.watch(currentUserProvider);
    final flags      = ref.watch(featureFlagsProvider);
    final submitState = ref.watch(submitClaimRequestProvider);

    final item = itemAsync.valueOrNull;
    final me   = meAsync.valueOrNull;

    final myRequestsAsync = ref.watch(
      watchMyRequestForItemProvider(widget.itemId, me?.uid ?? ''),
    );
    final existingRequest = myRequestsAsync.valueOrNull
        ?.where((r) => r.status != RequestStatus.cancelled)
        .firstOrNull;

    if (itemAsync.isLoading || meAsync.isLoading || myRequestsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (item == null || me == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: _kBg, elevation: 0),
        body: const Center(child: Text('Item not found.')),
      );
    }

    if (existingRequest != null) {
      return _AlreadySubmittedScreen(
        title: 'Claim Request',
        itemTitle: item.title,
        request: existingRequest,
      );
    }

    final hasSecret = item.secretQuestion != null && flags.secretQuestionEnabled;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kInk900),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Claim Request',
              style: TextStyle(
                color: _kInk900,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              item.title,
              style: const TextStyle(
                color: _kInk500,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Item summary card ──────────────────────────────────────────
            _ItemSummaryCard(item: item),
            const SizedBox(height: 14),

            // ── Your info card ─────────────────────────────────────────────
            _FieldLabel(label: 'Your info'),
            const SizedBox(height: 6),
            _UserInfoCard(user: me),
            const SizedBox(height: 14),

            // ── Description (optional) ─────────────────────────────────────
            _FieldLabel(
              label: 'Description',
              hint: 'optional',
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: _kInk800),
              decoration: _inputDecoration(
                hint:
                    'e.g. Brown leather bifold wallet, has my Krungthai card, '
                    '2x KMUTT student-clinic stamps inside. I lost it near CB2 '
                    'vending machine yesterday around 3pm.',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Help the poster verify it\'s yours — distinguishing details, '
              'where you lost it, contents inside, etc.',
              style: TextStyle(
                fontSize: 12,
                color: _kInk400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // ── Secret Question block (inline, if enabled) ─────────────────
            if (hasSecret) ...[
              _SecretQuestionBlock(
                question: item.secretQuestion!,
                controller: _answerCtrl,
                error: _answerError,
                onChanged: (_) => setState(() => _answerError = null),
              ),
              const SizedBox(height: 14),
            ],

            // ── Submit button ──────────────────────────────────────────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kInk200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: submitState.isLoading ? null : _submit,
              child: submitState.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send claim request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.01,
                      ),
                    ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Secret Question modal (shown when tapping "Answer" in modal style) ─
      // (inline style is always shown above; modal kept as overlay for later)
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.hint});
  final String  label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kInk500,
            letterSpacing: 0.04,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 6),
          Text(
            hint!,
            style: const TextStyle(
              fontSize: 11,
              color: _kInk400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _ItemSummaryCard extends StatelessWidget {
  const _ItemSummaryCard({required this.item});
  final dynamic item; // Item entity

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        (item.imageUrls as List<String>?)?.isNotEmpty == true
            ? item.imageUrls.first as String
            : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _photoPlaceholder(),
              ),
            )
          else
            _photoPlaceholder(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kInk900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.location as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kInk500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _kInk100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, color: _kInk400, size: 24),
      );
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});
  final dynamic user; // User entity

  @override
  Widget build(BuildContext context) {
    final name = '${user.firstName} ${user.lastName}';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kInk200,
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _kInk800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _kInk900,
                ),
              ),
              Text(
                'ID ${user.studentId}  ·  ${user.telephone}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kInk500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecretQuestionBlock extends StatelessWidget {
  const _SecretQuestionBlock({
    required this.question,
    required this.controller,
    required this.onChanged,
    this.error,
  });

  final String              question;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String?             error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPrimary50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: _kPrimary700),
              SizedBox(width: 6),
              Text(
                'Secret Question',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _kPrimary800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Question text
          Text(
            '"$question"',
            style: const TextStyle(
              fontSize: 14.5,
              color: _kInk800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Answer input
          _FieldLabel(
            label: 'Your answer',
            hint: error,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            autofocus: false,
            style: const TextStyle(fontSize: 14, color: _kInk800),
            decoration: _inputDecoration(
              hint: 'Type your answer…',
              hasError: error != null,
            ),
          ),
          const SizedBox(height: 6),

          // Footer hint
          const Text(
            'No hints. The poster will verify your answer manually.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _kInk500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlreadySubmittedScreen extends StatelessWidget {
  const _AlreadySubmittedScreen({
    required this.title,
    required this.itemTitle,
    required this.request,
  });

  final String title;
  final String itemTitle;
  final ItemRequest request;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, Color bg) = switch (request.status) {
      RequestStatus.pending  => ('Pending review', _kPrimary700, _kPrimary50),
      RequestStatus.approved => ('Approved', const Color(0xFF166534), const Color(0xFFDCFCE7)),
      RequestStatus.rejected => ('Rejected', const Color(0xFF991B1B), const Color(0xFFFFE4E6)),
      RequestStatus.cancelled => ('Cancelled', _kInk500, _kInk100),
    };

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kInk900),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _kInk900, fontSize: 17, fontWeight: FontWeight.w700)),
            Text(itemTitle,
                style: const TextStyle(
                    color: _kInk500, fontSize: 12, fontWeight: FontWeight.w400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 56, color: _kPrimary),
            const SizedBox(height: 16),
            const Text(
              'Already submitted',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kInk900),
            ),
            const SizedBox(height: 8),
            const Text(
              'You already have a request for this item.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kInk500, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: () => context.push(
                  '/item/${request.itemId}/request/${request.id}',
                ),
                child: const Text('View my request',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: _kBorder),
                ),
                onPressed: () => context.pop(),
                child: const Text('Go back',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kInk800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  bool hasError = false,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: _kInk400),
      filled: true,
      fillColor: _kSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFB23A28) : _kBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFB23A28) : _kPrimary400,
          width: 1.5,
        ),
      ),
    );
