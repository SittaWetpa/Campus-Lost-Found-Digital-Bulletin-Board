import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_lost_found/config/router/app_router.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';

const _amber = Color(0xFFCA8A04);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginNotifierProvider);

    ref.listen(loginNotifierProvider, (_, state) {
      if (state.hasError) {
        final error = state.error;
        final message =
            error is Failure ? error.message : 'Login failed. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Campus Lost & Found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Subtitle with KMUTT highlighted
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'KMUTT',
                          style: TextStyle(
                            color: _amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' digital bulletin board'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // KMUTT EMAIL label + field
                  const Text(
                    'KMUTT EMAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'pun.wo@mail.kmutt.ac.th',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required.';
                      }
                      if (!RegExp(r'^[^@]+@mail\.kmutt\.ac\.th$')
                          .hasMatch(value.trim())) {
                        return 'Only @mail.kmutt.ac.th emails are allowed.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // PASSWORD label + field
                  const Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Sign in button
                  FilledButton(
                    onPressed: loginState.isLoading ? null : _submit,
                    child: loginState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  // Create account link
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.register),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        children: [
                          TextSpan(text: 'New to Lost & Found? '),
                          TextSpan(
                            text: 'Create account',
                            style: TextStyle(
                              color: _amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info box
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EDE0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5D9C5)),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        children: [
                          TextSpan(text: '🔒 Only '),
                          TextSpan(
                            text: '@mail.kmutt.ac.th',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                              text:
                                  ' accounts can sign in.\nDemo: any seeded email + any password works.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
