import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/profile/presentation/providers/profile_provider.dart';

const _kAmber    = Color(0xFFA06200); // R5(c) — was 0xFFD98A0E; AA-safe for white text + text-on-light
const _kBg       = Color(0xFFFBF7EC);
const _kBorder   = Color(0xFFE6DDC4);
const _kInk500   = Color(0xFF7A6F5B);
const _kInk900   = Color(0xFF1B1610);
const _kSurface2 = Color(0xFFF6EFDC);

Color _avatarColor(String uid) {
  const colors = [
    Color(0xFFD98A0E), Color(0xFFB76E05), Color(0xFF2F7D3E),
    Color(0xFF2A5D8F), Color(0xFFC94A3E), Color(0xFF7A6F5B), Color(0xFF8A5103),
  ];
  final hash = uid.codeUnits.fold(0, (a, c) => a + c);
  return colors[hash % colors.length];
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl  = TextEditingController();
  final TextEditingController _telephoneCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  void _initControllers() {
    if (_initialized) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text  = user.lastName;
    _telephoneCtrl.text = user.telephone;
    _initialized = true;
  }

  Future<void> _pickAndUpload(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final rawExt = picked.name.split('.').last;
    await ref.read(uploadAvatarNotifierProvider.notifier).upload(
          uid: uid,
          bytes: bytes,
          extension: rawExt,
        );
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(editProfileNotifierProvider.notifier).save(
          uid: uid,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          telephone: _telephoneCtrl.text.trim(),
        );
  }

  InputDecoration _readOnlyDecoration() => InputDecoration(
        filled: true,
        fillColor: _kSurface2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
      );

  @override
  Widget build(BuildContext context) {
    _initControllers();

    final userAsync      = ref.watch(currentUserProvider);
    final saveState      = ref.watch(editProfileNotifierProvider);
    final uploadState    = ref.watch(uploadAvatarNotifierProvider);

    ref.listen<AsyncValue<void>>(editProfileNotifierProvider, (prev, state) {
      if (state.hasError) {
        final error = state.error;
        final msg = error is Failure ? error.message : 'Failed to update profile.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (!state.isLoading && !state.hasError && prev?.isLoading == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Color(0xFF2F7D3E),
          ),
        );
        Navigator.of(context).pop();
      }
    });

    ref.listen<AsyncValue<void>>(uploadAvatarNotifierProvider, (_, state) {
      if (state.hasError) {
        final error = state.error;
        final msg = error is Failure ? error.message : 'Failed to upload photo.';
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
          'Edit profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kInk900),
        ),
        centerTitle: false,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load profile.')),
        data: (user) {
          if (user == null) return const Center(child: Text('No profile found.'));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Avatar row ──────────────────────────────────────────
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: _avatarColor(user.uid),
                            backgroundImage: user.avatarUrl != null
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? Text(
                                    '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          if (uploadState.isLoading)
                            const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton(
                            onPressed: uploadState.isLoading
                                ? null
                                : () => _pickAndUpload(user.uid),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kInk900,
                              side: const BorderSide(color: _kBorder),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Change photo'),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JPG or PNG. Max 2 MB.',
                            style: TextStyle(fontSize: 12, color: _kInk500),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── First name + Last name ────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'First name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _kAmber),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required.';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Last name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _kAmber),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required.';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Phone number ─────────────────────────────────────────
                  TextFormField(
                    controller: _telephoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      hintText: '08x-xxx-xxxx',
                      hintStyle: const TextStyle(color: _kInk500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kAmber),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required.';
                      if (!RegExp(r'^0\d{9}$').hasMatch(v.trim())) {
                        return 'Must be a 10-digit number starting with 0.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Email (read-only) ────────────────────────────────────
                  TextFormField(
                    initialValue: user.email,
                    enabled: false,
                    style: const TextStyle(color: _kInk500),
                    decoration: _readOnlyDecoration().copyWith(
                      labelText: 'Email (read-only)',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Student ID (read-only) ───────────────────────────────
                  TextFormField(
                    initialValue: user.studentId,
                    enabled: false,
                    style: const TextStyle(color: _kInk500),
                    decoration: _readOnlyDecoration().copyWith(
                      labelText: 'Student ID (read-only)',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Save button ──────────────────────────────────────────
                  FilledButton(
                    onPressed: saveState.isLoading ? null : () => _save(user.uid),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAmber,
                      disabledBackgroundColor: const Color(0xFFC2B89F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: saveState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
