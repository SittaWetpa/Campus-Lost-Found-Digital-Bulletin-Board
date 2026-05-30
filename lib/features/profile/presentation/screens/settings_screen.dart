import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/profile/presentation/providers/profile_provider.dart';

const _kAmber  = Color(0xFFA06200); // R5(c) — was 0xFFD98A0E; AA-safe amber for text
const _kBg     = Color(0xFFFBF7EC);
const _kBorder = Color(0xFFE6DDC4);
const _kInk500 = Color(0xFF7A6F5B);
const _kInk900 = Color(0xFF1B1610);

Color _avatarColor(String uid) {
  const colors = [
    Color(0xFFD98A0E), Color(0xFFB76E05), Color(0xFF2F7D3E),
    Color(0xFF2A5D8F), Color(0xFFC94A3E), Color(0xFF7A6F5B), Color(0xFF8A5103),
  ];
  final hash = uid.codeUnits.fold(0, (a, c) => a + c);
  return colors[hash % colors.length];
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("You'll be returned to the login screen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _kInk500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(loginNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: _kAmber, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync     = ref.watch(currentUserProvider);
    final prefsAsync    = ref.watch(userPreferencesProvider);
    final notifierState = ref.watch(preferencesNotifierProvider);

    ref.listen<AsyncValue<void>>(loginNotifierProvider, (_, state) {
      if (state.hasError) {
        final error = state.error;
        final msg = error is Failure ? error.message : 'Sign out failed. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EDE0),
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kInk900),
        ),
        centerTitle: false,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load profile.')),
        data: (user) {
          if (user == null) return const Center(child: Text('No profile found.'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile card ─────────────────────────────────────────────
              _Card(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _avatarColor(user.uid),
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: GoogleFonts.fraunces(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kInk900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: const TextStyle(fontSize: 13, color: _kInk500),
                          ),
                          Text(
                            'ID ${user.studentId} · ${user.telephone}',
                            style: const TextStyle(fontSize: 12, color: _kInk500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => context.push(AppRoutes.editProfile),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kInk900,
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Preferences section header ────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: _kInk500,
                  ),
                ),
              ),

              // ── Preferences card ─────────────────────────────────────────
              _Card(
                padding: EdgeInsets.zero,
                child: prefsAsync.when(
                  loading: () => const _NotificationsRow(value: false, onChanged: null),
                  error: (_, __) => const _NotificationsRow(value: false, onChanged: null),
                  data: (prefs) => _NotificationsRow(
                    value: prefs.notificationsEnabled,
                    onChanged: notifierState.isLoading
                        ? null
                        : (v) => ref
                            .read(preferencesNotifierProvider.notifier)
                            .setNotificationsEnabled(value: v),
                  ),
                ),
              ),

              // ── Developer section (admin only — WBS 2.18) ────────────────
              if (user.isAdmin) ...[
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'DEVELOPER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: _kInk500,
                    ),
                  ),
                ),
                _Card(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _DeveloperRow(
                        label: 'Remote Config',
                        sub: 'Feature flags · WBS 2.13',
                        onTap: () => context.push(AppRoutes.adminRemoteConfig),
                      ),
                      const Divider(height: 1, color: _kBorder),
                      _DeveloperRow(
                        label: 'Rollback Plan',
                        sub: 'secret_question_enabled · WBS 2.13',
                        onTap: () => context.push(AppRoutes.adminRollbackPlan),
                      ),
                      const Divider(height: 1, color: _kBorder),
                      _DeveloperRow(
                        label: 'Debug Menu',
                        sub: 'Crashlytics test crashes · WBS 2.12',
                        onTap: () => context.push(AppRoutes.adminDebugMenu),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Sign out button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showSignOutDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kInk900,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F3C2A0A),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DeveloperRow extends StatelessWidget {
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _DeveloperRow({required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kInk900,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 12, color: _kInk500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: _kInk500),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _NotificationsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text(
        'Notifications',
        style: TextStyle(fontSize: 14, color: _kInk900),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: _kAmber,
      activeTrackColor: const Color(0x66D98A0E),
    );
  }
}
