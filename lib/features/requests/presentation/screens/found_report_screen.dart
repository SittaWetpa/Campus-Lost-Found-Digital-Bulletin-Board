import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_providers.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/submit_found_report_use_case.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/item_request_provider.dart';
import 'package:campus_lost_found/features/requests/presentation/providers/submit_request_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBg        = Color(0xFFF9F5E8);
const _kSurface   = Colors.white;
const _kBorder    = Color(0xFFE6DDC4);
const _kPrimary   = Color(0xFFD98A0E);
const _kPrimary400 = Color(0xFFE9A534);
const _kInk900    = Color(0xFF1B1610);
const _kInk800    = Color(0xFF2A241B);
const _kInk500    = Color(0xFF7A6F5B);
const _kInk400    = Color(0xFF9C9179);
const _kInk200    = Color(0xFFE2DAC1);
const _kInfo      = Color(0xFF2A5D8F);
const _kInfoBg    = Color(0xFFE0ECF5);
const _kDanger    = Color(0xFFB23A28);

class FoundReportScreen extends ConsumerStatefulWidget {
  const FoundReportScreen({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<FoundReportScreen> createState() => _FoundReportScreenState();
}

class _FoundReportScreenState extends ConsumerState<FoundReportScreen> {
  final _messageCtrl = TextEditingController();
  XFile? _pickedPhoto;
  bool   _uploadingPhoto = false;
  String? _messageError;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _pickedPhoto = picked);
  }

  Future<void> _submit() async {
    final item = ref.read(watchItemProvider(widget.itemId)).valueOrNull;
    final me   = ref.read(currentUserProvider).valueOrNull;
    if (item == null || me == null) return;

    final msg = _messageCtrl.text.trim();
    if (msg.length < 20) {
      setState(() => _messageError =
          'Please describe the item (at least 20 characters)');
      return;
    }
    setState(() => _messageError = null);

    // Upload photo if one was picked.
    String? photoUrl;
    if (_pickedPhoto != null) {
      setState(() => _uploadingPhoto = true);
      try {
        final bytes   = await _pickedPhoto!.readAsBytes();
        final storage = ref.read(storageRepositoryProvider);
        final ts      = DateTime.now().millisecondsSinceEpoch;
        photoUrl = await storage.uploadBytes(
          bytes,
          'request_photos/$ts.jpg',
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed. Submitting without photo.')),
        );
      } finally {
        if (mounted) setState(() => _uploadingPhoto = false);
      }
    }

    await ref.read(submitFoundReportProvider.notifier).submit(
          SubmitFoundReportParams(
            itemId: widget.itemId,
            requesterId: me.uid,
            requesterName: '${me.firstName} ${me.lastName}',
            requesterContact: me.telephone,
            studentId: me.studentId,
            message: msg,
            photoUrl: photoUrl,
          ),
        );

    if (!mounted) return;
    final state = ref.read(submitFoundReportProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send found report. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Found report sent')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync    = ref.watch(watchItemProvider(widget.itemId));
    final meAsync      = ref.watch(currentUserProvider);
    final submitState  = ref.watch(submitFoundReportProvider);
    final item         = itemAsync.valueOrNull;
    final me           = meAsync.valueOrNull;

    final myRequestsAsync = ref.watch(
      watchMyRequestForItemProvider(widget.itemId, me?.uid ?? ''),
    );
    final existingRequest = myRequestsAsync.valueOrNull
        ?.where((r) => r.status != RequestStatus.cancelled)
        .firstOrNull;

    if (itemAsync.isLoading || meAsync.isLoading || myRequestsAsync.isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (item == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: _kBg, elevation: 0),
        body: const Center(child: Text('Item not found.')),
      );
    }

    if (existingRequest != null) {
      return _AlreadySubmittedScreen(
        title: 'Found Report',
        itemTitle: item.title,
        request: existingRequest,
      );
    }

    final isBusy = submitState.isLoading || _uploadingPhoto;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kInk900),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Found Report',
              style: TextStyle(
                color: _kInk900,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              item.title,
              style: const TextStyle(
                color: _kInk500,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Info banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kInfoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kInfo.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'HELP VERIFY IT\'S REALLY THE ITEM',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _kInfo,
                      letterSpacing: 0.04,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Describe distinctive details (color, marks, where you found it). '
                    'A photo helps a lot.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kInk800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Description field ──────────────────────────────────────────
            _FieldLabel(
              label: 'Description',
              errorText: _messageError,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              onChanged: (_) {
                if (_messageError != null) setState(() => _messageError = null);
              },
              style: const TextStyle(fontSize: 14, color: _kInk800),
              decoration: _inputDecoration(
                hint: 'e.g. White AirPods Pro case with a tiny scratch on the '
                    'hinge — I found them by the printer in LIB-1.',
                hasError: _messageError != null,
              ),
            ),
            if (_messageError != null) ...[
              const SizedBox(height: 4),
              Text(
                _messageError!,
                style: const TextStyle(fontSize: 12, color: _kDanger),
              ),
            ],
            const SizedBox(height: 14),

            // ── Optional photo ─────────────────────────────────────────────
            const _FieldLabel(label: 'Optional photo'),
            const SizedBox(height: 6),
            _pickedPhoto == null
                ? _PhotoPickButton(onTap: _pickPhoto)
                : _PhotoPreview(
                    file: _pickedPhoto!,
                    onRemove: () => setState(() => _pickedPhoto = null),
                  ),
            const SizedBox(height: 20),

            // ── Submit button ──────────────────────────────────────────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kInk200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send found report',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.01,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.errorText});
  final String  label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _kInk500,
        letterSpacing: 0.04,
      ),
    );
  }
}

class _PhotoPickButton extends StatelessWidget {
  const _PhotoPickButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: _kInk400,
            width: 1.5,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dashed border effect via CustomPaint
            const Icon(Icons.camera_alt_outlined, size: 22, color: _kInk500),
            const SizedBox(height: 4),
            const Text(
              'Attach photo',
              style: TextStyle(fontSize: 12, color: _kInk500),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.file, required this.onRemove});
  final XFile       file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              file.path,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _kInk200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image_outlined,
                    color: _kInk400, size: 32),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0x99000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlreadySubmittedScreen extends StatelessWidget {
  const _AlreadySubmittedScreen({
    required this.title,
    required this.itemTitle,
    required this.request,
  });

  final String title;
  final String itemTitle;
  final ItemRequest request;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, Color bg) = switch (request.status) {
      RequestStatus.pending  => ('Pending review', const Color(0xFF8A5103), const Color(0xFFFFF8E9)),
      RequestStatus.approved => ('Approved', const Color(0xFF166534), const Color(0xFFDCFCE7)),
      RequestStatus.rejected => ('Rejected', const Color(0xFF991B1B), const Color(0xFFFFE4E6)),
      RequestStatus.cancelled => ('Cancelled', const Color(0xFF7A6F5B), const Color(0xFFF1EBD8)),
    };

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kInk900),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: _kInk900, fontSize: 17, fontWeight: FontWeight.w700)),
            Text(itemTitle,
                style: const TextStyle(
                    color: _kInk500, fontSize: 12, fontWeight: FontWeight.w400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 56, color: _kPrimary),
            const SizedBox(height: 16),
            const Text(
              'Already submitted',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kInk900),
            ),
            const SizedBox(height: 8),
            const Text(
              'You already have a request for this item.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _kInk500, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: () => context.push(
                  '/item/${request.itemId}/request/${request.id}',
                ),
                child: const Text('View my request',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: _kBorder),
                ),
                onPressed: () => context.pop(),
                child: const Text('Go back',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kInk800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hint,
  bool hasError = false,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: _kInk400),
      filled: true,
      fillColor: _kSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? _kDanger : _kBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? _kDanger : _kPrimary400,
          width: 1.5,
        ),
      ),
    );
