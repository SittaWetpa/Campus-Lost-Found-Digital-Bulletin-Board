// WBS 2.8 — SimilarPostsPanel widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/presentation/widgets/similar_posts_panel.dart';

Item _makeItem({
  required String id,
  required String title,
  required String location,
  DateTime? createdAt,
}) {
  return Item(
    id: id,
    title: title,
    description: '',
    category: ItemCategory.founder,
    status: ItemStatus.active,
    location: location,
    contact: '0812345678',
    imageUrls: const [],
    userId: 'user-1',
    createdAt: createdAt ?? DateTime.now(),
    occurredAt: DateTime.now(),
    itemTaxonomy: ItemTaxonomy.electronics,
  );
}

Widget wrap(AsyncValue<List<Item>> state) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => Scaffold(body: SimilarPostsPanel(state: state))),
    GoRoute(path: '/item/:id', builder: (_, __) => const Scaffold()),
  ]);
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  group('SimilarPostsPanel — WBS 2.8', () {
    testWidgets('renders nothing when data list is empty', (tester) async {
      await tester.pumpWidget(wrap(const AsyncData([])));
      await tester.pump();

      expect(find.text('Active Founder posts in this category'), findsNothing);
    });

    testWidgets('renders nothing while loading', (tester) async {
      await tester.pumpWidget(wrap(const AsyncLoading()));
      await tester.pump();

      expect(find.text('Active Founder posts in this category'), findsNothing);
    });

    testWidgets('renders nothing on error', (tester) async {
      await tester.pumpWidget(
        wrap(AsyncError(Exception('fail'), StackTrace.empty)),
      );
      await tester.pump();

      expect(find.text('Active Founder posts in this category'), findsNothing);
    });

    testWidgets('renders cards when data has items', (tester) async {
      final items = [
        _makeItem(id: 'a', title: 'Found iPhone', location: 'Library'),
        _makeItem(id: 'b', title: 'Found AirPods', location: 'Cafeteria'),
        _makeItem(id: 'c', title: 'Found Laptop', location: 'Gate B'),
      ];

      await tester.pumpWidget(wrap(AsyncData(items)));
      await tester.pump();

      expect(find.text('Active Founder posts in this category'), findsOneWidget);
      expect(find.text('Found iPhone'), findsOneWidget);
      expect(find.text('Found AirPods'), findsOneWidget);
      expect(find.text('Found Laptop'), findsOneWidget);
    });

    testWidgets('shows header only once regardless of item count', (tester) async {
      final items = List.generate(
        5,
        (i) => _makeItem(id: 'item-$i', title: 'Item $i', location: 'Loc $i'),
      );

      await tester.pumpWidget(wrap(AsyncData(items)));
      await tester.pump();

      expect(
        find.text('Active Founder posts in this category'),
        findsOneWidget,
      );
    });
  });
}
