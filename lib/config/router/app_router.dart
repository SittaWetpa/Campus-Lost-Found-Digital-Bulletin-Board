import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/auth/domain/entities/auth_user.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/screens/login_screen.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const feed = '/feed';
  static const otpVerify = '/otp-verify';
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final listenable = ValueNotifier<AsyncValue<AuthUser?>>(const AsyncLoading());

  ref.listen(
    authStateProvider,
    (_, value) => listenable.value = value,
    fireImmediately: true,
  );
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authValue = listenable.value;
      if (authValue.isLoading) return null;

      final isLoggedIn = authValue.valueOrNull != null;
      final goingToLogin = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !goingToLogin) return AppRoutes.login;
      if (isLoggedIn && goingToLogin) return AppRoutes.feed;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Feed — WBS 1.2')),
        ),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OTP Verify — WBS 0.5')),
        ),
      ),
    ],
  );
}