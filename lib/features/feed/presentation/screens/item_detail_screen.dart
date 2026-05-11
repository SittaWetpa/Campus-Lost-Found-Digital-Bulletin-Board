import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/item_category_chip.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/photo_gallery.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/request_card.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/sensitive_banner.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/widgets/resubmit_banner.dart';
import 'package:campus_lost_found/shared/widgets/confirm_dialog.dart';
import 'package:campus_lost_found/shared/widgets/walk_in_badge.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(watchItemProvider(widget.id));

    return itemAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Failed to load item.')),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found.')),
          );
        }
        return _ItemDetailView(item: item);
      },
    );
  }
}

class _ItemDetailView extends ConsumerWidget {
  const _ItemDetailView({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final flags = ref.watch(featureFlagsProvider);
    final isPoster = item.userId == authUser?.uid;
    final isSensitive = item.isSensitive;
    final isWalkIn = item.source == ItemSource.qrWalkIn;
    final securityPhone = flags.securityOfficeContact;

    final posterAsync = ref.watch(getUserByIdProvider(item.userId));
    // Poster: all requests (inbox). Visitor: own requests only — the filtered
    // query satisfies Firestore list-query rules for non-poster users.
    final requestsAsync = isPoster
        ? ref.watch(watchRequestsForItemProvider(item.id))
        : ref.watch(
            watchMyRequestForItemProvider(item.id, authUser?.uid ?? ''));

    final requests = requestsAsync.valueOrNull ?? [];
    final pending =
        requests.where((r) => r.status == RequestStatus.pending).toList();
    // Only consider pending/approved requests as "active" — cancelled or
    // rejected requests should not block the user from submitting a new one.
    final myRequest = authUser == null
        ? null
        : requests.cast<ItemRequest?>().firstWhere(
              (r) =>
                  r?.requesterId == authUser.uid &&
                  (r?.status == RequestStatus.pending ||
                      r?.status == RequestStatus.approved),
              orElse: () => null,
            );

    final actionState = ref.watch(itemDetailActionNotifierProvider);

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
      backgroundColor: AppTokens.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTokens.bg,
            elevation: 0,
            pinned: true,
            title: Text(
              item.category == ItemCategory.founder ? 'Found item' : 'Lost item',
            ),
            actions: [
              if (isPoster && item.status == ItemStatus.active) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push(AppRoutes.editPostPath(item.id)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppTokens.seeker,
                  onPressed: () => _onDeleteTap(context, ref, pending),
                ),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrls.isNotEmpty)
                  PhotoGallery(photos: item.imageUrls),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChipsRow(
                        item: item,
                        isSensitive: isSensitive,
                        isWalkIn: isWalkIn,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      _MetaRow(item: item, isSensitive: isSensitive),
                      if (!isSensitive && item.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.55,
                            color: AppTokens.ink800,
                          ),
                        ),
                      ],
                      const Divider(height: 32, color: AppTokens.border),
                      _PosterRow(
                        item: item,
                        isPoster: isPoster,
                        isSensitive: isSensitive,
                        posterAsync: posterAsync,
                      ),
                      if (!isPoster &&
                          item.category == ItemCategory.founder &&
                          !isSensitive &&
                          item.secretQuestion != null &&
                          flags.secretQuestionEnabled)
                        const _SecretQuestionNotice(),
                      const SizedBox(height: 16),
                      if (!isPoster && item.status == ItemStatus.active)
                        _VisitorActions(
                          item: item,
                          isSensitive: isSensitive,
                          isWalkIn: isWalkIn,
                          myRequest: myRequest,
                          isCheckingRequest: requestsAsync.isLoading,
                          securityPhone: securityPhone,
                          requesterId: authUser?.uid,
                          onCancelRequest:
                              myRequest?.status == RequestStatus.pending
                                  ? () => _confirmCancelRequest(
                                        context,
                                        ref,
                                        item.id,
                                        myRequest!.id,
                                      )
                                  : null,
                        ),
                      if (isPoster &&
                          isSensitive &&
                          item.status == ItemStatus.active) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTokens.primary600,
                              side: const BorderSide(color: AppTokens.primary400),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: actionState.isLoading
                                ? null
                                : () => _confirmResolve(context, ref),
                            child: const Text(
                                'Mark as resolved (handed to security)'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (isPoster && !isSensitive)
                        _RequestsInbox(
                          item: item,
                          requests: requests,
                          pending: pending,
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

  Future<void> _confirmCancelRequest(
    BuildContext context,
    WidgetRef ref,
    String itemId,
    String requestId,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Cancel your request?',
      body: 'The poster will see this request as cancelled. '
          'You can submit a new request later if needed.',
      confirmLabel: 'Yes, cancel it',
      cancelLabel: 'Keep',
      tone: ConfirmTone.danger,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(itemDetailActionNotifierProvider.notifier)
        .cancel(itemId: itemId, requestId: requestId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
    }
  }

  Future<void> _onDeleteTap(
    BuildContext context,
    WidgetRef ref,
    List<ItemRequest> pending,
  ) async {
    if (pending.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.rMd),
          ),
          title: const Text('Resolve requests first'),
          content: Text(
            'This post has ${pending.length} pending request(s). '
            'Review and approve or reject them before deleting.',
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppTokens.ink700,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete this post?',
      body: 'This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      tone: ConfirmTone.danger,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(itemDetailActionNotifierProvider.notifier)
        .delete(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
      context.pop();
    }
  }

  Future<void> _confirmResolve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Mark as resolved?',
      body:
          'Confirm you have handed this sensitive item to the Security Office.',
      confirmLabel: 'Yes, mark resolved',
      cancelLabel: 'Cancel',
      tone: ConfirmTone.success,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(itemDetailActionNotifierProvider.notifier).resolve(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post marked as resolved')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({
    required this.item,
    required this.isSensitive,
    required this.isWalkIn,
  });

  final Item item;
  final bool isSensitive;
  final bool isWalkIn;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _CategoryChip(category: item.category),
        if (item.itemTaxonomy != null)
          ItemCategoryChip(taxonomy: item.itemTaxonomy!),
        _StatusBadge(status: item.status),
        if (isSensitive)
          _chip('🔒 Sensitive', AppTokens.warn, AppTokens.warnBg),
        if (isWalkIn) const WalkInBadge(),
        if (item.editedAt != null)
          Text(
            'Edited · ${_relativeTime(item.editedAt!)}',
            style: const TextStyle(fontSize: 12, color: AppTokens.ink500),
          ),
      ],
    );
  }

  Widget _chip(String label, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
          ),
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    final isFounder = category == ItemCategory.founder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isFounder ? AppTokens.successBg : AppTokens.seekerBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isFounder ? 'Found · Founder' : 'Lost · Seeker',
        style: TextStyle(
          color: isFounder ? AppTokens.success : AppTokens.seeker,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == ItemStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppTokens.successBg : AppTokens.ink100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: isActive ? AppTokens.success : AppTokens.ink600,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item, required this.isSensitive});

  final Item item;
  final bool isSensitive;

  @override
  Widget build(BuildContext context) {
    final isWalkIn = item.source == ItemSource.qrWalkIn;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _metaItem(Icons.location_on_outlined, item.location),
        _metaItem(Icons.access_time, _formatFull(item.occurredAt)),
        if ((isSensitive || isWalkIn) && item.expiresAt != null)
          _metaItem(
            Icons.hourglass_bottom_outlined,
            'Expires ${_shortDate(item.expiresAt!)}',
            color: AppTokens.warn,
          ),
      ],
    );
  }

  Widget _metaItem(IconData icon, String text, {Color? color}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTokens.ink600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? AppTokens.ink600,
            ),
          ),
        ],
      );
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({
    required this.item,
    required this.isPoster,
    required this.isSensitive,
    required this.posterAsync,
  });

  final Item item;
  final bool isPoster;
  final bool isSensitive;
  final AsyncValue<dynamic> posterAsync;

  @override
  Widget build(BuildContext context) {
    final isWalkIn = item.source == ItemSource.qrWalkIn;
    final isLoading = posterAsync.isLoading;
    final poster = posterAsync.valueOrNull;

    final String? resolvedAvatarUrl =
        isWalkIn ? null : (poster?.avatarUrl ?? item.posterAvatarUrl);
    final String name;
    if (isWalkIn) {
      name = 'Anonymous walk-in';
    } else if (isLoading && item.posterName == null) {
      name = '';
    } else if (poster != null) {
      name = '${poster.firstName} ${poster.lastName}'.trim();
    } else if (item.posterName != null && item.posterName!.isNotEmpty) {
      name = item.posterName!;
    } else {
      name = 'Unknown poster';
    }

    final String subtitle = isWalkIn
        ? 'Submitted via QR · ${_relativeTime(item.createdAt)}'
        : 'Posted ${_relativeTime(item.createdAt)}';

    final String avatarInitial;
    if (isWalkIn) {
      avatarInitial = 'QR';
    } else if (poster != null && poster.firstName.isNotEmpty) {
      avatarInitial = poster.firstName[0].toUpperCase();
    } else if (item.posterName != null && item.posterName!.isNotEmpty) {
      avatarInitial = item.posterName![0].toUpperCase();
    } else {
      avatarInitial = '?';
    }

    return Row(
      children: [
        if (isWalkIn)
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTokens.ink100,
              shape: BoxShape.circle,
            ),
            child: const Text(
              'QR',
              style: TextStyle(
                color: AppTokens.ink500,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          )
        else
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTokens.ink100,
            backgroundImage: resolvedAvatarUrl != null
                ? NetworkImage(resolvedAvatarUrl)
                : null,
            child: resolvedAvatarUrl == null
                ? isLoading && item.posterName == null
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        avatarInitial,
                        style: const TextStyle(
                          color: AppTokens.ink700,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                : null,
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTokens.ink800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTokens.ink500,
                ),
              ),
            ],
          ),
        ),
        if (!isPoster && !isSensitive && !isWalkIn && item.contact.isNotEmpty)
          GestureDetector(
            onTap: () => _launchTel(item.contact),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTokens.primary100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, size: 12, color: AppTokens.primary600),
                  const SizedBox(width: 4),
                  Text(
                    item.contact,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.primary600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SecretQuestionNotice extends StatelessWidget {
  const _SecretQuestionNotice();

  // Prototype uses a CSS dashed border; Flutter's Border.all only renders solid.
  // We approximate with a 1px solid primary-400 outline on surface-2 — the closest
  // stock-Flutter analogue without pulling in a `dotted_border` dependency.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.surface2,
        borderRadius: BorderRadius.circular(AppTokens.rSm),
        border: Border.all(color: AppTokens.primary400),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppTokens.primary600),
          SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTokens.ink700,
                ),
                children: [
                  TextSpan(text: 'This item is protected by a '),
                  TextSpan(
                    text: 'secret question',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ". You'll need to answer it to submit a claim."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorActions extends ConsumerWidget {
  const _VisitorActions({
    required this.item,
    required this.isSensitive,
    required this.isWalkIn,
    required this.myRequest,
    required this.isCheckingRequest,
    required this.securityPhone,
    required this.requesterId,
    this.onCancelRequest,
  });

  final Item item;
  final bool isSensitive;
  final bool isWalkIn;
  final ItemRequest? myRequest;
  final bool isCheckingRequest;
  final String securityPhone;
  final String? requesterId;
  final VoidCallback? onCancelRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSensitive || isWalkIn) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.warn,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.phone, size: 16),
              label: Text('Contact Security Office · $securityPhone'),
              onPressed: () => _launchTel(securityPhone),
            ),
            if (isSensitive) ...[
              const SizedBox(height: 14),
              const SensitiveBanner(),
            ],
            if (!isSensitive && isWalkIn) ...[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'This item was handed in anonymously through the QR walk-in form. '
                  'To claim it, please visit the Security Office in person with proof of ownership.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTokens.ink600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (myRequest != null) {
      return Card(
        color: AppTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          side: const BorderSide(color: AppTokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RequestStatusBadge(status: myRequest!.status),
                  const SizedBox(width: 8),
                  Text(
                    'Your request · ${_relativeTime(myRequest!.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.ink500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.ink800,
                    side: const BorderSide(color: AppTokens.border),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () => RequestDetailRoute(
                    itemId: item.id,
                    reqId: myRequest!.id,
                  ).push(context),
                  child: const Text('View my request'),
                ),
              ),
              if (onCancelRequest != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.seeker,
                      side: const BorderSide(color: AppTokens.seeker),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: onCancelRequest,
                    child: const Text('Cancel request'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final decisionAsync = requesterId == null || requesterId!.isEmpty
        ? const AsyncValue<ResubmitDecision?>.data(null)
        : ref.watch(resubmitDecisionProvider(item.id, requesterId!))
            .whenData<ResubmitDecision?>((d) => d);
    final decision = decisionAsync.valueOrNull;
    final isPolicyLoading = decisionAsync.isLoading;
    final canSubmit = !isCheckingRequest &&
        !isPolicyLoading &&
        (decision == null || decision.allowed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (decision != null && requesterId != null)
            ResubmitBanner(
              decision: decision,
              itemId: item.id,
              requesterId: requesterId!,
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTokens.ink100,
                disabledForegroundColor: AppTokens.ink500,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: const StadiumBorder(),
              ),
              onPressed: canSubmit
                  ? () => context.push(
                        item.category == ItemCategory.founder
                            ? '/claim/${item.id}'
                            : '/found-report/${item.id}',
                      )
                  : null,
              child: isCheckingRequest || isPolicyLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      item.category == ItemCategory.founder
                          ? 'Submit Claim Request'
                          : 'Submit Found Report',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, Color bg) = switch (status) {
      RequestStatus.pending => (AppTokens.warn, AppTokens.warnBg),
      RequestStatus.approved => (AppTokens.success, AppTokens.successBg),
      RequestStatus.rejected => (AppTokens.seeker, AppTokens.seekerBg),
      RequestStatus.cancelled => (AppTokens.ink600, AppTokens.ink100),
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
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RequestsInbox extends StatelessWidget {
  const _RequestsInbox({
    required this.item,
    required this.requests,
    required this.pending,
  });

  final Item item;
  final List<ItemRequest> requests;
  final List<ItemRequest> pending;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Requests inbox',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    color: AppTokens.ink900,
                  ),
            ),
            Text(
              '${requests.length} total · ${pending.length} pending',
              style: const TextStyle(fontSize: 12, color: AppTokens.ink500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap a request to review and approve or reject.',
          style: TextStyle(fontSize: 12, color: AppTokens.ink600),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTokens.warnBg,
              borderRadius: BorderRadius.circular(AppTokens.rSm),
              border: Border.all(color: AppTokens.warnBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    size: 16, color: AppTokens.warn),
                const SizedBox(width: 8),
                Text(
                  'Action needed · ${pending.length} request${pending.length > 1 ? 's' : ''} waiting',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.warn,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (requests.isEmpty)
          Card(
            color: AppTokens.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.rSm),
              side: const BorderSide(color: AppTokens.border),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No requests yet.',
                  style: TextStyle(color: AppTokens.ink500),
                ),
              ),
            ),
          )
        else
          ...requests.map(
            (r) => RequestCard(
              request: r,
              showDecideHint: r.status == RequestStatus.pending,
              onTap: () =>
                  RequestDetailRoute(itemId: item.id, reqId: r.id).push(context),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _launchTel(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

String _formatFull(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _shortDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}
