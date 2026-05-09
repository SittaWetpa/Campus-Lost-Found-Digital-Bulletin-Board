// WBS 2.18 — RemoteConfigViewerScreen widget tests

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/admin/presentation/screens/remote_config_viewer_screen.dart';

class _FakeFeatureFlagService implements FeatureFlagService {
  _FakeFeatureFlagService({
    this.flags = const FeatureFlags(
      secretQuestionEnabled: true,
      sensitiveItemEnabled: true,
      securityOfficeContact: '02-470-9999',
      sensitiveCategories: ['credit_card', 'id_card', 'passport'],
    ),
    DateTime? lastFetch,
  }) : _lastFetch = lastFetch ?? DateTime.fromMillisecondsSinceEpoch(0);

  final FeatureFlags flags;
  final DateTime _lastFetch;
  int fetchCallCount = 0;

  @override
  FeatureFlags get currentFlags => flags;

  @override
  Future<void> fetchAndActivate() async {
    fetchCallCount++;
  }

  @override
  DateTime get lastFetchTime => _lastFetch;

  @override
  bool get secretQuestionEnabled => flags.secretQuestionEnabled;

  @override
  bool get sensitiveItemEnabled => flags.sensitiveItemEnabled;

  @override
  String get securityOfficeContact => flags.securityOfficeContact;
}

Widget _wrap(_FakeFeatureFlagService fake) => ProviderScope(
      overrides: [featureFlagsProvider.overrideWith((_) => fake)],
      child: const MaterialApp(home: RemoteConfigViewerScreen()),
    );

void main() {
  group('RemoteConfigViewerScreen — WBS 2.18', () {
    testWidgets(
      'WBS 2.18-03 — renders all four Remote Config keys with current values',
      (tester) async {
        final fake = _FakeFeatureFlagService();
        await tester.pumpWidget(_wrap(fake));
        await tester.pumpAndSettle();

        expect(find.text('secret_question_enabled'), findsOneWidget);
        expect(find.text('sensitive_item_enabled'), findsOneWidget);
        expect(find.text('security_office_contact'), findsOneWidget);
        expect(find.text('sensitive_categories'), findsOneWidget);
        expect(find.text('"02-470-9999"'), findsOneWidget);
        // Two booleans render as TRUE badges.
        expect(find.text('TRUE'), findsNWidgets(2));
        // Sensitive category chips.
        expect(find.text('credit_card'), findsOneWidget);
        expect(find.text('id_card'), findsOneWidget);
        expect(find.text('passport'), findsOneWidget);
      },
    );

    testWidgets(
      'WBS 2.18-04 — banner shows "not yet fetched" when lastFetchTime is the epoch',
      (tester) async {
        final fake = _FakeFeatureFlagService();
        await tester.pumpWidget(_wrap(fake));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Config not yet fetched'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'WBS 2.18-05 — tapping "Fetch & activate" calls FeatureFlagService.fetchAndActivate',
      (tester) async {
        final fake = _FakeFeatureFlagService();
        await tester.pumpWidget(_wrap(fake));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Fetch & activate'));
        await tester.pumpAndSettle();

        expect(fake.fetchCallCount, 1);
      },
    );

    testWidgets(
      'WBS 2.18-06 — DISABLED flag renders FALSE badge',
      (tester) async {
        final fake = _FakeFeatureFlagService(
          flags: const FeatureFlags(
            secretQuestionEnabled: false,
            sensitiveItemEnabled: true,
            securityOfficeContact: '02-470-9999',
            sensitiveCategories: ['credit_card'],
          ),
        );
        await tester.pumpWidget(_wrap(fake));
        await tester.pumpAndSettle();

        expect(find.text('FALSE'), findsOneWidget);
        expect(find.text('TRUE'), findsOneWidget);
      },
    );
  });
}
