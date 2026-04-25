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
  static const login = '/login';
  static const register = '/register';
  static const feed = '/feed';
  static const otpVerify = '/otp-verify';
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
      final goingToLogin = state.matchedLocation == AppRoutes.login;
      final goingToRegister = state.matchedLocation == AppRoutes.register;
      final goingToOtp = state.matchedLocation == AppRoutes.otpVerify;

      if (!isLoggedIn) {
        return (goingToLogin || goingToRegister) ? null : AppRoutes.login;
      }

      // Logged in — wait for user profile before deciding OTP guard.
      final userValue = userListenable.value;
      if (userValue.isLoading) return null;

      final user = userValue.valueOrNull;
      if (user != null && !user.emailVerified) {
        return goingToOtp ? null : AppRoutes.otpVerify;
      }

      // Verified — push away from login/register/otp screens.
      if (goingToLogin || goingToRegister || goingToOtp) return AppRoutes.feed;
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
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) => const OtpVerifyScreen(),
      ),
    ],
  );
}