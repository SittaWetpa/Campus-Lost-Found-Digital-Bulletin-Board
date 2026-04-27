import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/register_screen.dart';

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
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Feed — WBS 1.2')),
        ),
      ),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Item Detail — id: ${state.pathParameters['id']} — WBS 1.3'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.post,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Post Form — WBS 1.4')),
        ),
      ),
      GoRoute(
        path: AppRoutes.editPost,
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Edit Post — id: ${state.pathParameters['id']} — WBS 2.6'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.myPosts,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('My Posts — WBS 1.7')),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Settings — WBS 1.6')),
        ),
        routes: [
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Edit Profile — WBS 1.8')),
            ),
          ),
        ],
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