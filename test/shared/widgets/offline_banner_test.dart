import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lost_found/core/network/connectivity_provider.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/shared/widgets/offline_banner.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('01 banner is invisible when online', (tester) async {
    await tester.pumpWidget(_wrap(
      const OfflineBanner(),
      overrides: [
        isOfflineProvider.overrideWithValue(false),
        itemsFeedLastSyncedAtProvider.overrideWithValue(null),
      ],
    ));

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.text('Offline · Showing cached data · No cached data'),
        findsNothing);
  });

  testWidgets('02 banner is visible when offline', (tester) async {
    await tester.pumpWidget(_wrap(
      const OfflineBanner(),
      overrides: [
        isOfflineProvider.overrideWithValue(true),
        itemsFeedLastSyncedAtProvider.overrideWithValue(null),
      ],
    ));

    expect(
      find.textContaining('Offline · Showing cached data'),
      findsOneWidget,
    );
  });

  testWidgets('03 shows "No cached data" when lastSyncedAt is null',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const OfflineBanner(),
      overrides: [
        isOfflineProvider.overrideWithValue(true),
        itemsFeedLastSyncedAtProvider.overrideWithValue(null),
      ],
    ));

    expect(
      find.text('Offline · Showing cached data · No cached data'),
      findsOneWidget,
    );
  });

  testWidgets('04 shows relative time when lastSyncedAt is set',
      (tester) async {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    await tester.pumpWidget(_wrap(
      const OfflineBanner(),
      overrides: [
        isOfflineProvider.overrideWithValue(true),
        itemsFeedLastSyncedAtProvider.overrideWithValue(fiveMinutesAgo),
      ],
    ));

    expect(find.textContaining('5m ago'), findsOneWidget);
  });
}
