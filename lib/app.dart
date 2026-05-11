import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/messaging/root_scaffold_messenger.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';

class CampusLostFoundApp extends ConsumerWidget {
  const CampusLostFoundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final baseSans = GoogleFonts.plusJakartaSansTextTheme();
    return MaterialApp.router(
      title: 'Campus Lost & Found',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTokens.primary500,
          primary: AppTokens.primary500,
          surface: AppTokens.surface,
          error: AppTokens.seeker,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppTokens.bg,
        dividerColor: AppTokens.border,
        textTheme: baseSans.copyWith(
          headlineSmall: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: AppTokens.ink900,
          ),
          titleLarge: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTokens.ink900,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppTokens.bg,
          foregroundColor: AppTokens.ink900,
          elevation: 0,
          titleTextStyle: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTokens.ink900,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTokens.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTokens.primary500),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTokens.seeker),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTokens.seeker),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
