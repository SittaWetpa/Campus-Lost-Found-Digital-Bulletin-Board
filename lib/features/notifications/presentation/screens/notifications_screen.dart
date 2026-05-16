import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/notifications/domain/entities/app_notification.dart';
import 'package:campus_lost_found/features/notifications/presentation/providers/notification_providers.dart';

// Light blue for T2 (Found Report) — no matching token in AppTokens.
const _foundReportBg = Color(0xFFE3F0FB);

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<NotificationType> _selectedTypes = {};

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(myNotificationsProvider);
    final unreadCount = ref.watch(myUnreadNotificationCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      appBar: AppBar(
        backgroundColor: AppTokens.bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTokens.ink500,
                ),
              ),
          ],
        ),
        titleTextStyle: const TextStyle(
          color: AppTokens.ink900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppTokens.ink700),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref
                  .read(notificationActionNotifierProvider.notifier)
                  .markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppTokens.primary600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTokens.ink700),
            onSelected: (v) {
              if (v == 'clearRead') {
                ref
                    .read(notificationActionNotifierProvider.notifier)
                    .clearRead();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clearRead',
                child: Text('Clear read notifications'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(
            selected: _selectedTypes,
            onToggle: (t) {
              setState(() {
                if (_selectedTypes.contains(t)) {
                  _selectedTypes.remove(t);
                } else {
                  _selectedTypes.add(t);
                }
              });
            },
          ),
          Expanded(
            child: notifsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load notifications.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTokens.ink500),
                  ),
                ),
              ),
              data: (all) {
                final items = _selectedTypes.isEmpty
                    ? all
                    : all.where((n) => _selectedTypes.contains(n.type)).toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedTypes.isEmpty
                          ? 'No notifications yet.'
                          : 'No notifications match the selected filters.',
                      style: const TextStyle(color: AppTokens.ink500),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length + 1,
                  itemBuilder: (_, i) {
                    if (i == items.length) return const _AutoArchiveNotice();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: _NotificationTile(notification: items[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final Set<NotificationType> selected;
  final ValueChanged<NotificationType> onToggle;

  const _FilterChips({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in _chipMeta.entries) ...[
                    _TypeFilterChip(
                      type: entry.key,
                      label: entry.value.label,
                      selected: selected.contains(entry.key),
                      onTap: () => onToggle(entry.key),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'FCM trigger types',
            style: TextStyle(fontSize: 11, color: AppTokens.ink500),
          ),
        ],
      ),
    );
  }

  static const _chipMeta = {
    NotificationType.claimRequest: (label: 'T1',),
    NotificationType.foundReport: (label: 'T2',),
    NotificationType.requestApproved: (label: 'T3',),
    NotificationType.requestDeclined: (label: 'T4',),
  };
}

class _TypeFilterChip extends StatelessWidget {
  final NotificationType type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = _typeVisuals(type);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? visuals.bg : AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.pill),
            border: Border.all(
              color: selected ? visuals.fg : AppTokens.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(visuals.icon, size: 14, color: visuals.fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.isRead;
    final visuals = _typeVisuals(notification.type);
    final notifier = ref.read(notificationActionNotifierProvider.notifier);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTokens.seekerBg,
          borderRadius: BorderRadius.circular(AppTokens.rMd),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: AppTokens.seeker),
      ),
      onDismissed: (_) => notifier.delete(notification.id),
      child: Semantics(
        label: '${_titleFor(notification)}: ${_bodyFor(notification)}',
        button: true,
        child: Material(
          color: visuals.bg,
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.rMd),
            onTap: () async {
              if (unread) await notifier.markAsRead(notification.id);
              if (context.mounted) {
                context.push(AppRoutes.itemDetailPath(notification.itemId));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTokens.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(visuals.icon, size: 20, color: visuals.fg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _titleFor(notification),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppTokens.ink900,
                                ),
                              ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: visuals.fg,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bodyFor(notification),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTokens.ink700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTokens.ink500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      _RoundIconButton(
                        icon: unread ? Icons.check : Icons.check_circle,
                        tooltip: 'Mark as read',
                        enabled: unread,
                        onTap: () => notifier.markAsRead(notification.id),
                      ),
                      const SizedBox(height: 8),
                      _RoundIconButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete',
                        onTap: () => notifier.delete(notification.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(AppNotification n) {
    switch (n.type) {
      case NotificationType.claimRequest:
        return 'New Claim Request';
      case NotificationType.foundReport:
        return 'Found Report';
      case NotificationType.requestApproved:
        return 'Request Approved';
      case NotificationType.requestDeclined:
        return 'Request Declined';
    }
  }

  String _bodyFor(AppNotification n) {
    final name = n.requesterName ?? 'Someone';
    switch (n.type) {
      case NotificationType.claimRequest:
        return '$name submitted a Claim Request on your post "${n.itemTitle}"';
      case NotificationType.foundReport:
        return '$name reported finding "${n.itemTitle}"';
      case NotificationType.requestApproved:
        return '"${n.itemTitle}" — contact the poster to arrange a handover';
      case NotificationType.requestDeclined:
        return 'Your request for "${n.itemTitle}" was declined';
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTokens.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppTokens.border),
          ),
          child: Icon(
            icon,
            size: 14,
            color: enabled ? AppTokens.ink700 : AppTokens.ink500,
          ),
        ),
      ),
    );
  }
}

class _AutoArchiveNotice extends StatelessWidget {
  const _AutoArchiveNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'Read notifications auto-archive after 30 days',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: AppTokens.ink500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Type → visual mapping (icon + tinted background + accent color) ──────────

class _TypeVisuals {
  final IconData icon;
  final Color bg;
  final Color fg;
  const _TypeVisuals(this.icon, this.bg, this.fg);
}

_TypeVisuals _typeVisuals(NotificationType type) {
  switch (type) {
    case NotificationType.claimRequest:
      return const _TypeVisuals(
        Icons.local_offer_outlined,
        AppTokens.primary100,
        AppTokens.primary600,
      );
    case NotificationType.foundReport:
      return const _TypeVisuals(
        Icons.search,
        _foundReportBg,
        AppTokens.info,
      );
    case NotificationType.requestApproved:
      return const _TypeVisuals(
        Icons.check_circle_outline,
        AppTokens.successBg,
        AppTokens.success,
      );
    case NotificationType.requestDeclined:
      return const _TypeVisuals(
        Icons.cancel_outlined,
        AppTokens.seekerBg,
        AppTokens.seeker,
      );
  }
}
