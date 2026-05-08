// WBS 2.18 — Admin route guard

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/app.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/domain/entities/feature_flags.dart';
import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/admin/presentation/screens/remote_config_viewer_screen.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/feed_screen.dart';

const _authUser = AuthUser(uid: 'u1', email: 'lead@mail.kmutt.ac.th');

final _regularUser = User(
  uid: 'u1',
  email: 'lead@mail.kmutt.ac.th',
  firstName: 'Reg',
  lastName: 'User',
  studentId: '64000000',
  telephone: '0812345678',
  emailVerified: true,
  createdAt: DateTime(2025),
);

final _adminUser = User(
  uid: 'u1',
  email: 'lead@mail.kmutt.ac.th',
  firstName: 'Lead',
  lastName: 'Admin',
  studentId: '64000099',
  telephone: '0812345678',
  emailVerified: true,
  createdAt: DateTime(2025),
  isAdmin: true,
);

class _FakeFeatureFlagService implements FeatureFlagService {
  static const _flags = FeatureFlags(
    secretQuestionEnabled: true,
    sensitiveItemEnabled: true,
    securityOfficeContact: '02-470-9999',
    sensitiveCategories: ['credit_card'],
  );

  @override
  FeatureFlags get currentFlags => _flags;

  @override
  Future<void> fetchAndActivate() async {}

  @override
  DateTime get lastFetchTime => DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get secretQuestionEnabled => true;

  @override
  bool get sensitiveItemEnabled => true;

  @override
  String get securityOfficeContact => '02-470-9999';
}

ProviderContainer _container({required User user}) => ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((_) => Stream.value(_authUser)),
        currentUserProvider.overrideWith((_) => Stream.value(user)),
        feedItemsProvider.overrideWith((_) => Stream.value(const <Item>[])),
        featureFlagsProvider.overrideWith((_) => _FakeFeatureFlagService()),
      ],
    );

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const CampusLostFoundApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Admin route guard — WBS 2.18', () {
    testWidgets(
      'WBS 2.18-10 — non-admin navigating to /admin/remote-config '
      'is redirected to /feed and a snackbar is shown',
      (tester) async {
        final container = _container(user: _regularUser);
        addTearDown(container.dispose);

        await _pumpApp(tester, container);
        // Initial location is FeedScreen (verified user).
        expect(find.byType(FeedScreen), findsOneWidget);

        container.read(appRouterProvider).go(AppRoutes.adminRemoteConfig);
        await tester.pumpAndSettle();

        expect(find.byType(FeedScreen), findsOneWidget);
        expect(find.byType(RemoteConfigViewerScreen), findsNothing);
        expect(find.text('Admin access required'), findsOneWidget);
      },
    );

    testWidgets(
      'WBS 2.18-11 — admin navigating to /admin/remote-config '
      'lands on the viewer screen (no redirect)',
      (tester) async {
        final container = _container(user: _adminUser);
        addTearDown(container.dispose);

        await _pumpApp(tester, container);

        container.read(appRouterProvider).go(AppRoutes.adminRemoteConfig);
        await tester.pumpAndSettle();

        expect(find.byType(RemoteConfigViewerScreen), findsOneWidget);
        expect(find.text('Admin access required'), findsNothing);
      },
    );
  });
}
