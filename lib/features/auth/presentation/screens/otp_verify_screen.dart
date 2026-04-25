import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/otp_provider.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  Future<void> _sendOtp() async {
    await ref.read(otpNotifierProvider.notifier).sendOtp();
    if (mounted && !ref.read(otpNotifierProvider).hasError) {
      setState(() => _otpSent = true);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    await ref
        .read(otpNotifierProvider.notifier)
        .verifyOtp(_codeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpNotifierProvider);

    ref.listen(otpNotifierProvider, (previous, state) {
      if (state.hasError) {
        final error = state.error;
        final message =
            error is Failure ? error.message : 'Something went wrong. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Check your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the 6-digit code sent to your @mail.kmutt.ac.th address.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: (otpState.isLoading ||
                          !_otpSent ||
                          _codeController.text.trim().length < 6)
                      ? null
                      : _verify,
                  child: otpState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: otpState.isLoading ? null : _sendOtp,
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}