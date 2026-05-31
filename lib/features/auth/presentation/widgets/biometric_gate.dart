import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_lost_found/core/constants/app_constants.dart';
import 'package:campus_lost_found/core/theme/app_tokens.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/biometric_provider.dart';

/// R1(b) — Wraps the routed app and enforces a biometric / device-credential
/// check when the app returns to the foreground with an active session.
///
/// On Web this is a transparent pass-through: WebAuthn is the intended Web
/// equivalent and `local_auth` has no Web implementation, so the lifecycle
/// observer is never installed and the lock overlay never renders.
class BiometricGate extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(biometricLockProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        lock.markBackgrounded();
      case AppLifecycleState.resumed:
        lock.authenticateAndUnlock();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = kIsWeb ? false : ref.watch(biometricLockProvider);
    return Stack(
      children: [
        widget.child,
        if (locked)
          _LockOverlay(
            onUnlock: () =>
                ref.read(biometricLockProvider.notifier).authenticateAndUnlock(),
          ),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockOverlay({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 56, color: AppTokens.ink700),
              const SizedBox(height: 16),
              Text(
                AppConstants.biometricLockTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.biometricLockMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTokens.ink600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text(AppConstants.biometricUnlockLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
