// WBS 2.18 — RollbackPlanScreen widget tests

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/admin/presentation/screens/rollback_plan_screen.dart';

class _FakeFeatureFlagService implements FeatureFlagService {
  _FakeFeatureFlagService({required this.flags});
  final FeatureFlags flags;

  @override
  FeatureFlags get currentFlags => flags;

  @override
  Future<void> fetchAndActivate() async {}

  @override
  DateTime get lastFetchTime => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get secretQuestionEnabled => flags.secretQuestionEnabled;

  @override
  bool get sensitiveItemEnabled => flags.sensitiveItemEnabled;

  @override
  String get securityOfficeContact => flags.securityOfficeContact;
}

FeatureFlags _flagsWith({required bool secretQuestionEnabled}) => FeatureFlags(
      secretQuestionEnabled: secretQuestionEnabled,
      sensitiveItemEnabled: true,
      securityOfficeContact: '02-470-9999',
      sensitiveCategories: const ['credit_card'],
    );

Widget _wrap(FeatureFlags flags) => ProviderScope(
      overrides: [
        featureFlagsProvider
            .overrideWith((_) => _FakeFeatureFlagService(flags: flags)),
      ],
      child: const MaterialApp(home: RollbackPlanScreen()),
    );

void main() {
  group('RollbackPlanScreen — WBS 2.18', () {
    testWidgets(
      'WBS 2.18-07 — flag enabled: status banner shows "Feature currently ENABLED"',
      (tester) async {
        await tester.pumpWidget(_wrap(_flagsWith(secretQuestionEnabled: true)));
        await tester.pumpAndSettle();

        expect(find.text('Feature currently ENABLED'), findsOneWidget);
        expect(find.text('Feature currently DISABLED — rollback applied'),
            findsNothing);
      },
    );

    testWidgets(
      'WBS 2.18-08 — flag disabled: banner shows "rollback applied" message',
      (tester) async {
        await tester.pumpWidget(_wrap(_flagsWith(secretQuestionEnabled: false)));
        await tester.pumpAndSettle();

        expect(find.text('Feature currently DISABLED — rollback applied'),
            findsOneWidget);
        expect(find.text('Feature currently ENABLED'), findsNothing);
      },
    );

    testWidgets(
      'WBS 2.18-09 — checklist item toggles checked state on tap',
      (tester) async {
        // Tall screen so the checklist is in the initial viewport — avoids
        // the ListView-lazy-build vs. ensureVisible chicken-and-egg.
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(_flagsWith(secretQuestionEnabled: false)));
        await tester.pumpAndSettle();

        // Before tap: no check icons rendered.
        expect(find.byIcon(Icons.check), findsNothing);

        final firstChecklistRow = find.textContaining('Cold-restart the app');
        expect(firstChecklistRow, findsOneWidget);

        await tester.tap(firstChecklistRow);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      },
    );
  });
}
