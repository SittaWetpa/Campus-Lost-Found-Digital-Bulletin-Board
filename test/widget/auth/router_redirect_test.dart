import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/app.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/otp_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/feed_screen.dart';

// Stub that prevents OtpVerifyScreen's auto-send from hitting Cloud Functions.
class _FakeOtpNotifier extends OtpNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> sendOtp() async {}

  @override
  Future<void> verifyOtp(String code) async {}
}

// ---------------------------------------------------------------------------
// Shared test fixtures
// ---------------------------------------------------------------------------

const _authUser = AuthUser(uid: 'u1', email: 'test@mail.kmutt.ac.th');

final _verifiedUser = User(
  uid: 'u1',
  email: 'test@mail.kmutt.ac.th',
  firstName: 'Test',
  lastName: 'User',
  studentId: '64000000',
  telephone: '0812345678',
  emailVerified: true,
  createdAt: DateTime(2025),
);

final _unverifiedUser = User(
  uid: 'u1',
  email: 'test@mail.kmutt.ac.th',
  firstName: 'Test',
  lastName: 'User',
  studentId: '64000000',
  telephone: '0812345678',
  emailVerified: false,
  createdAt: DateTime(2025),
);

// ---------------------------------------------------------------------------
// Helper: build the full app with a ProviderContainer so the test can
// read providers (e.g. appRouterProvider) directly.
// ---------------------------------------------------------------------------
Future<void> _buildApp(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const CampusLostFoundApp(),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // 1. Auth-state redirect guards (initial navigation)
  // =========================================================================
  group('Auth-state redirect guards', () {
    testWidgets('unauthenticated user is redirected to /login', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            currentUserProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
        'verified user is redirected away from /login to /feed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
            currentUserProvider
                .overrideWith((ref) => Stream.value(_verifiedUser)),
            feedItemsProvider.overrideWith((ref) => Stream.value(<Item>[])),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FeedScreen), findsOneWidget);
    });

    testWidgets(
        'authenticated but unverified user is redirected to /otp-verify',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
            currentUserProvider
                .overrideWith((ref) => Stream.value(_unverifiedUser)),
            otpNotifierProvider.overrideWith(_FakeOtpNotifier.new),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerifyScreen), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. Sign-out regression — WBS 4.3 integration test (simulated as widget)
  // =========================================================================
  group('Sign-out regression', () {
    testWidgets('sign out redirects to /login automatically', (tester) async {
      final authCtrl = StreamController<AuthUser?>();
      final userCtrl = StreamController<User?>();
      addTearDown(() async {
        await authCtrl.close();
        await userCtrl.close();
      });

      // Start authenticated & verified — router should land on /feed.
      authCtrl.add(_authUser);
      userCtrl.add(_verifiedUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => authCtrl.stream),
            currentUserProvider.overrideWith((ref) => userCtrl.stream),
            feedItemsProvider.overrideWith((ref) => Stream.value(<Item>[])),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FeedScreen), findsOneWidget);

      // Simulate sign-out: emit null from both streams.
      authCtrl.add(null);
      userCtrl.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. Deep-link simulation — authenticated navigation to parameterised routes
  //    WBS 4.3: "cold-start with deep link /item/{id} → Detail Screen"
  // =========================================================================
  group('Deep-link simulation — authenticated', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
          currentUserProvider
              .overrideWith((ref) => Stream.value(_verifiedUser)),
        ],
      );
    });

    tearDown(() => container.dispose());

    testWidgets(
        'navigate to /item/:id renders Item Detail with correct id',
        (tester) async {
      await _buildApp(tester, container);

      container.read(appRouterProvider).go('/item/abc123');
      await tester.pumpAndSettle();

      expect(
        find.text('Item Detail — id: abc123 — WBS 1.3'),
        findsOneWidget,
      );
    });

    testWidgets(
        'navigate to /post/:id/edit renders Edit Post with correct id',
        (tester) async {
      await _buildApp(tester, container);

      container.read(appRouterProvider).go('/post/item-99/edit');
      await tester.pumpAndSettle();

      expect(
        find.text('Edit Post — id: item-99 — WBS 2.6'),
        findsOneWidget,
      );
    });

    testWidgets(
        'ItemDetailRoute value object navigates to correct screen',
        (tester) async {
      await _buildApp(tester, container);

      const route = ItemDetailRoute(id: 'deep-link-id');
      container.read(appRouterProvider).go(route.location);
      await tester.pumpAndSettle();

      expect(
        find.text('Item Detail — id: deep-link-id — WBS 1.3'),
        findsOneWidget,
      );
    });

    testWidgets(
        'EditPostRoute value object navigates to correct screen',
        (tester) async {
      await _buildApp(tester, container);

      const route = EditPostRoute(id: 'post-42');
      container.read(appRouterProvider).go(route.location);
      await tester.pumpAndSettle();

      expect(
        find.text('Edit Post — id: post-42 — WBS 2.6'),
        findsOneWidget,
      );
    });
  });

  // =========================================================================
  // 4. Authenticated navigation — parameterless routes
  // =========================================================================
  group('Authenticated navigation — parameterless routes', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
          currentUserProvider
              .overrideWith((ref) => Stream.value(_verifiedUser)),
        ],
      );
    });

    tearDown(() => container.dispose());

    testWidgets('navigate to /post renders Post Form placeholder',
        (tester) async {
      await _buildApp(tester, container);

      container.read(appRouterProvider).go(AppRoutes.post);
      await tester.pumpAndSettle();

      expect(find.text('Post Form — WBS 1.4'), findsOneWidget);
    });

    testWidgets('navigate to /my-posts renders My Posts placeholder',
        (tester) async {
      await _buildApp(tester, container);

      container.read(appRouterProvider).go(AppRoutes.myPosts);
      await tester.pumpAndSettle();

      expect(find.text('My Posts — WBS 1.7'), findsOneWidget);
    });

    testWidgets('navigate to /settings renders Settings placeholder',
        (tester) async {
      await _buildApp(tester, container);

      container.read(appRouterProvider).go(AppRoutes.settings);
      await tester.pumpAndSettle();

      expect(find.text('Settings — WBS 1.6'), findsOneWidget);
    });

    testWidgets(
        'navigate to /settings/edit-profile renders Edit Profile placeholder',
        (tester) async {
      await _buildApp(tester, container);

      container.read(appRouterProvider).go(AppRoutes.editProfile);
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile — WBS 1.8'), findsOneWidget);
    });
  });

  // =========================================================================
  // 5. Private-route guard — unauthenticated access to every protected path
  // =========================================================================
  group('Private-route guard — unauthenticated', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          currentUserProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
    });

    tearDown(() => container.dispose());

    final privateRoutes = [
      AppRoutes.feed,
      AppRoutes.post,
      AppRoutes.myPosts,
      AppRoutes.settings,
      AppRoutes.editProfile,
      '/item/abc',
      '/post/abc/edit',
    ];

    for (final path in privateRoutes) {
      testWidgets(
          'accessing $path unauthenticated redirects to /login',
          (tester) async {
        await _buildApp(tester, container);

        container.read(appRouterProvider).go(path);
        await tester.pumpAndSettle();

        expect(
          find.byType(LoginScreen),
          findsOneWidget,
          reason: 'Expected /login for unauthenticated access to $path',
        );
      });
    }
  });

  // =========================================================================
  // 6. OTP guard — verified user is not re-sent to /otp-verify
  // =========================================================================
  group('OTP guard — edge cases', () {
    testWidgets(
        'verified user navigating to /otp-verify is redirected to /feed',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
          currentUserProvider
              .overrideWith((ref) => Stream.value(_verifiedUser)),
          feedItemsProvider.overrideWith((ref) => Stream.value(<Item>[])),
        ],
      );
      addTearDown(container.dispose);

      await _buildApp(tester, container);

      container.read(appRouterProvider).go(AppRoutes.otpVerify);
      await tester.pumpAndSettle();

      // Guard pushes verified users away from /otp-verify back to /feed.
      expect(find.byType(FeedScreen), findsOneWidget);
      expect(find.byType(OtpVerifyScreen), findsNothing);
    });

    testWidgets(
        'unverified user navigating to /feed is redirected to /otp-verify',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_authUser)),
            currentUserProvider
                .overrideWith((ref) => Stream.value(_unverifiedUser)),
            otpNotifierProvider.overrideWith(_FakeOtpNotifier.new),
          ],
          child: const CampusLostFoundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OtpVerifyScreen), findsOneWidget);
    });
  });
}
