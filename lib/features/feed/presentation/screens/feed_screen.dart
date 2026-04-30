import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';

const _kBg     = Color(0xFFFBF7EC);
const _kBorder = Color(0xFFE6DDC4);
const _kInk500 = Color(0xFF7A6F5B);
const _kInk900 = Color(0xFF1B1610);

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final firstName = userAsync.valueOrNull?.firstName ?? '';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE0),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bulletin',
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kInk900,
                height: 1,
              ),
            ),
            if (firstName.isNotEmpty)
              Text(
                'Hi $firstName',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kInk500,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined, color: _kInk900),
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _kBorder),
        ),
      ),
      body: const Center(
        child: Text('Feed — WBS 1.2'),
      ),
    );
  }
}
