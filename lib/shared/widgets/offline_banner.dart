import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/core/network/connectivity_provider.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    if (!offline) return const SizedBox.shrink();

    final lastSynced = ref.watch(itemsFeedLastSyncedAtProvider);
    final syncText = lastSynced == null
        ? 'No cached data'
        : 'Last synced ${_relativeTime(lastSynced)}';

    return Container(
      width: double.infinity,
      color: const Color(0xFFF97316),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Text(
        'Offline · Showing cached data · $syncText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _relativeTime(DateTime past) {
    final diff = DateTime.now().difference(past);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
