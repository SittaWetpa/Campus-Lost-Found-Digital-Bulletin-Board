import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/photo_gallery.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/request_card.dart';
import 'package:campus_lost_found/features/feed/presentation/widgets/sensitive_banner.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
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
    final pending = requests.where((r) => r.status == RequestStatus.pending).toList();
    final myRequest = authUser == null
        ? null
        : requests.cast<ItemRequest?>().firstWhere(
              (r) => r?.requesterId == authUser.uid,
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
      backgroundColor: const Color(0xFFF5EDE0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF5EDE0),
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
                  color: Theme.of(context).colorScheme.error,
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
                if (isSensitive)
                  SensitiveBanner(securityPhone: securityPhone),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          height: 1.25,
                        ),
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
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                      const Divider(height: 32),
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
                        _SecretQuestionNotice(),
                      const SizedBox(height: 16),
                      if (!isPoster && item.status == ItemStatus.active)
                        _VisitorActions(
                          item: item,
                          isSensitive: isSensitive,
                          myRequest: myRequest,
                          securityPhone: securityPhone,
                        ),
                      if (isPoster && isSensitive && item.status == ItemStatus.active) ...[
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: actionState.isLoading
                                ? null
                                : () => _confirmResolve(context, ref),
                            child:
                                const Text('Mark as resolved (handed to security)'),
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

  void _onDeleteTap(
    BuildContext context,
    WidgetRef ref,
    List<ItemRequest> pending,
  ) {
    if (pending.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resolve requests first'),
          content: Text(
            'This post has ${pending.length} pending request(s). '
            'Review and approve or reject them before deleting.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(itemDetailActionNotifierProvider.notifier)
                  .delete(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted')),
                );
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmResolve(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as resolved?'),
        content: const Text(
          'Confirm you have handed this sensitive item to the Security Office.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(itemDetailActionNotifierProvider.notifier)
                  .resolve(item);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post marked as resolved')),
                );
              }
            },
            child: const Text('Yes, mark resolved'),
          ),
        ],
      ),
    );
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
        _StatusBadge(status: item.status),
        if (isSensitive)
          _chip('🔒 Sensitive', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
        if (isWalkIn) const WalkInBadge(),
        if (item.editedAt != null)
          Text(
            'Edited · ${_relativeTime(item.editedAt!)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
        color: isFounder ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isFounder ? 'FOUND · FOUNDER' : 'LOST · SEEKER',
        style: TextStyle(
          color:
              isFounder ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
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
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color:
              isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
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
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _metaItem(Icons.location_on_outlined, item.location),
        _metaItem(Icons.access_time, _formatFull(item.occurredAt)),
        if (isSensitive && item.expiresAt != null)
          _metaItem(
            Icons.hourglass_bottom_outlined,
            'Expires ${_shortDate(item.expiresAt!)}',
            color: const Color(0xFFD97706),
          ),
      ],
    );
  }

  Widget _metaItem(IconData icon, String text, {Color? color}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color ?? const Color(0xFF6B7280),
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
    final poster = posterAsync.valueOrNull;
    final name = poster != null
        ? '${poster.firstName} ${poster.lastName}'
        : 'Walk-in submission';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE5E7EB),
          backgroundImage: (poster?.avatarUrl != null)
              ? NetworkImage(poster!.avatarUrl!)
              : null,
          child: poster?.avatarUrl == null
              ? Text(
                  poster != null && poster.firstName.isNotEmpty
                      ? poster.firstName[0].toUpperCase()
                      : 'Q',
                  style: const TextStyle(
                    color: Color(0xFF374151),
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
                ),
              ),
              Text(
                'Posted ${_relativeTime(item.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        if (!isPoster && !isSensitive && item.contact.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone, size: 12, color: Color(0xFF3B82F6)),
                const SizedBox(width: 4),
                Text(
                  item.contact,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SecretQuestionNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF93C5FD),
          style: BorderStyle.solid,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "This item is protected by a secret question. You'll need to answer it to submit a claim.",
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorActions extends StatelessWidget {
  const _VisitorActions({
    required this.item,
    required this.isSensitive,
    required this.myRequest,
    required this.securityPhone,
  });

  final Item item;
  final bool isSensitive;
  final ItemRequest? myRequest;
  final String securityPhone;

  @override
  Widget build(BuildContext context) {
    if (isSensitive) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.phone, size: 16),
            label: Text('Contact Security Office · $securityPhone'),
            onPressed: () {},
          ),
        ),
      );
    }

    if (myRequest != null) {
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
              Row(
                children: [
                  _RequestStatusBadge(status: myRequest!.status),
                  const SizedBox(width: 8),
                  Text(
                    'Your request · ${_relativeTime(myRequest!.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => RequestDetailRoute(
                    itemId: item.id,
                    reqId: myRequest!.id,
                  ).push(context),
                  child: const Text('View my request'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCA8A04),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: const StadiumBorder(),
          ),
          onPressed: () => context.push(
            item.category == ItemCategory.founder
                ? '/claim/${item.id}'
                : '/found-report/${item.id}',
          ),
          child: Text(
            item.category == ItemCategory.founder
                ? 'Submit Claim Request'
                : 'Submit Found Report',
          ),
        ),
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
            const Text(
              'Requests inbox',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              '${requests.length} total · ${pending.length} pending',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (requests.isEmpty)
          Card(
            color: Colors.white,
            elevation: 0,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No requests yet.',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
          )
        else
          ...requests.map(
            (r) => RequestCard(
              request: r,
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
