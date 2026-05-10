import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/core/messaging/root_scaffold_messenger.dart';
import 'package:campus_lost_found/core/observability/app_logger_route_observer.dart';
import 'package:campus_lost_found/features/admin/presentation/screens/debug_menu_screen.dart';
import 'package:campus_lost_found/features/admin/presentation/screens/remote_config_viewer_screen.dart';
import 'package:campus_lost_found/features/admin/presentation/screens/rollback_plan_screen.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/register_screen.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/feed_screen.dart';
import 'package:campus_lost_found/features/feed/presentation/screens/item_detail_screen.dart';
import 'package:campus_lost_found/features/post/presentation/screens/post_form_screen.dart';
import 'package:campus_lost_found/features/requests/presentation/screens/claim_request_screen.dart';
import 'package:campus_lost_found/features/requests/presentation/screens/found_report_screen.dart';
import 'package:campus_lost_found/features/requests/presentation/screens/request_detail_screen.dart';
import 'package:campus_lost_found/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:campus_lost_found/features/profile/presentation/screens/settings_screen.dart';
part 'app_router.g.dart';

abstract final class AppRoutes {
  // Auth
  static const login     = '/login';
  static const register  = '/register';
  static const feed      = '/feed';
  static const otpVerify = '/otp-verify';

  // Feed & detail
  static const itemDetail = '/item/:id';

  // Post management
  static const post     = '/post';
  static const editPost = '/post/:id/edit';

  // Profile
  static const myPosts     = '/my-posts';
  static const settings    = '/settings';
  static const editProfile = '/settings/edit-profile';

  // Admin (WBS 2.18) — gated by isAdmin
  static const adminRemoteConfig = '/admin/remote-config';
  static const adminRollbackPlan = '/admin/rollback-plan';
  static const adminDebugMenu    = '/admin/debug-menu';
  static bool isAdminRoute(String location) =>
      location.startsWith('/admin/');

  // Request flows (WBS 2.4)
  static String claimPath(String itemId)       => '/claim/$itemId';
  static String foundReportPath(String itemId) => '/found-report/$itemId';

  // Typed path builders for parameterised routes
  static String itemDetailPath(String id) => '/item/$id';
  static String editPostPath(String id)   => '/post/$id/edit';

  // Routes that do not require authentication
  static const _publicRoutes = {login, register, otpVerify};
  static bool isPublic(String location) => _publicRoutes.contains(location);
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final authListenable =
      ValueNotifier<AsyncValue<AuthUser?>>(const AsyncLoading());
  final userListenable =
      ValueNotifier<AsyncValue<User?>>(const AsyncLoading());

  ref.listen(
    authStateProvider,
    (_, value) => authListenable.value = value,
    fireImmediately: true,
  );
  ref.listen(
    currentUserProvider,
    (_, value) => userListenable.value = value,
    fireImmediately: true,
  );
  ref.onDispose(() {
    authListenable.dispose();
    userListenable.dispose();
  });

  return GoRouter(
    initialLocation: AppRoutes.login,
    observers: [AppLoggerRouteObserver()],
    refreshListenable: Listenable.merge([authListenable, userListenable]),
    redirect: (context, state) {
      final authValue = authListenable.value;
      if (authValue.isLoading) return null;

      final isLoggedIn = authValue.valueOrNull != null;
      final isPublic = AppRoutes.isPublic(state.matchedLocation);
      final goingToOtp = state.matchedLocation == AppRoutes.otpVerify;

      if (!isLoggedIn) {
        return isPublic ? null : AppRoutes.login;
      }

      // Logged in — wait for user profile before deciding OTP guard.
      final userValue = userListenable.value;
      if (userValue.isLoading) return null;

      final user = userValue.valueOrNull;
      if (user != null && !user.emailVerified) {
        return goingToOtp ? null : AppRoutes.otpVerify;
      }

      // Admin guard (WBS 2.18) — /admin/* requires user.isAdmin
      if (AppRoutes.isAdminRoute(state.matchedLocation) &&
          (user == null || !user.isAdmin)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          rootScaffoldMessengerKey.currentState
            ?..clearSnackBars()
            ..showSnackBar(const SnackBar(
              content: Text('Admin access required'),
            ));
        });
        return AppRoutes.feed;
      }

      // Verified — push away from login/register/otp screens.
      if (isPublic) return AppRoutes.feed;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (context, state) =>
            ItemDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/item/:itemId/request/:reqId',
        builder: (context, state) => RequestDetailScreen(
          itemId: state.pathParameters['itemId']!,
          reqId: state.pathParameters['reqId']!,
        ),
      ),
      GoRoute(
        path: '/claim/:itemId',
        builder: (context, state) => ClaimRequestScreen(
          itemId: state.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        path: '/found-report/:itemId',
        builder: (context, state) => FoundReportScreen(
          itemId: state.pathParameters['itemId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.post,
        builder: (context, state) => const PostFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.editPost,
        builder: (context, state) =>
            PostFormScreen(editId: state.pathParameters['id']),
      ),
      GoRoute(
        path: AppRoutes.myPosts,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('My Posts — WBS 1.7')),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminRemoteConfig,
        builder: (context, state) => const RemoteConfigViewerScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRollbackPlan,
        builder: (context, state) => const RollbackPlanScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDebugMenu,
        builder: (context, state) => const DebugMenuScreen(),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Typed route value objects — compile-time-safe navigation for parameterised
// routes. Usage: ItemDetailRoute(id: item.id).go(context)
// ---------------------------------------------------------------------------

final class ItemDetailRoute {
  final String id;
  const ItemDetailRoute({required this.id});

  String get location => AppRoutes.itemDetailPath(id);
  void go(BuildContext context) => context.go(location);
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}

final class EditPostRoute {
  final String id;
  const EditPostRoute({required this.id});

  String get location => AppRoutes.editPostPath(id);
  void go(BuildContext context) => context.go(location);
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}

final class RequestDetailRoute {
  final String itemId;
  final String reqId;
  const RequestDetailRoute({required this.itemId, required this.reqId});

  String get location => '/item/$itemId/request/$reqId';
  void go(BuildContext context) => context.go(location);
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}

final class ClaimRequestRoute {
  final String itemId;
  const ClaimRequestRoute({required this.itemId});

  String get location => AppRoutes.claimPath(itemId);
  void go(BuildContext context) => context.go(location);
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}

final class FoundReportRoute {
  final String itemId;
  const FoundReportRoute({required this.itemId});

  String get location => AppRoutes.foundReportPath(itemId);
  void go(BuildContext context) => context.go(location);
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}