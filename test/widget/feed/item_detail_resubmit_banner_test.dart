// WBS 2.4.1 — ResubmitBanner widget tests.

import 'package:campus_lost_found/features/requests/domain/entities/resubmit_decision.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/widgets/resubmit_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('ResubmitBanner — WBS 2.4.1', () {
    testWidgets(
      '01 renders attempts-remaining copy when allowed with attemptsRemaining=2',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const ResubmitBanner(
              decision: ResubmitDecision.allowed(attemptsRemaining: 2),
              itemId: 'item-1',
              requesterId: 'user-1',
            ),
          ),
        );

        expect(
          find.text('Incorrect answer. 2 attempts remaining.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '02 renders permanent-block copy when reason is permanentBlock',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const ResubmitBanner(
              decision: ResubmitDecision.permanentBlock(),
              itemId: 'item-1',
              requesterId: 'user-1',
            ),
          ),
        );

        expect(
          find.text('You can no longer submit a request on this post.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '03 renders the cooldown countdown copy when reason is cooldown',
      (tester) async {
        final retryAfter =
            DateTime.now().add(const Duration(hours: 2, minutes: 15));

        await tester.pumpWidget(
          _wrap(
            ResubmitBanner(
              decision: ResubmitDecision.cooldown(retryAfter),
              itemId: 'item-1',
              requesterId: 'user-1',
            ),
            overrides: [
              cooldownRemainingProvider(retryAfter).overrideWith(
                (ref) => Stream<Duration>.value(
                  retryAfter.difference(DateTime.now()),
                ),
              ),
            ],
          ),
        );
        await tester.pump();

        expect(
          find.textContaining('You can submit a new request in'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '04 renders nothing when allowed with no attempts limit (non-SQ post)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const ResubmitBanner(
              decision: ResubmitDecision.allowed(),
              itemId: 'item-1',
              requesterId: 'user-1',
            ),
          ),
        );

        expect(find.byType(Container), findsNothing);
      },
    );
  });
}
