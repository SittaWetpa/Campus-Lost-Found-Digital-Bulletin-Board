import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/feed_provider.dart';
import 'package:campus_lost_found/features/post/domain/usecases/upload_post_photos_use_case.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_providers.dart';

const _kAmber = Color(0xFFCA8A04);
const _kGreen = Color(0xFF16A34A);
const _kRed = Color(0xFFE11D48);
const _kBg = Color(0xFFF5EDE0);

class PostFormScreen extends ConsumerStatefulWidget {
  const PostFormScreen({super.key, this.editId});

  final String? editId;

  @override
  ConsumerState<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends ConsumerState<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _sqCtrl;
  late final TextEditingController _saCtrl;

  ItemCategory _category = ItemCategory.founder;
  bool _isSensitive = false;
  DateTime _occurredAt = DateTime.now();
  List<String> _imageUrls = const [];

  Item? _editItem;
  bool _isLoadingEdit = false;
  bool _isUploadingPhoto = false;

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _sqCtrl = TextEditingController();
    _saCtrl = TextEditingController();
    _titleCtrl.addListener(_onTitleChanged);
    if (_isEdit) {
      _isLoadingEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditItem());
    }
  }

  @override
  void dispose() {
    _titleCtrl
      ..removeListener(_onTitleChanged)
      ..dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    _sqCtrl.dispose();
    _saCtrl.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (_category == ItemCategory.founder) {
      ref.read(similarPostsNotifierProvider.notifier).search(_titleCtrl.text);
    }
  }

  Future<void> _loadEditItem() async {
    try {
      final item =
          await ref.read(itemRepositoryProvider).getItemById(widget.editId!);
      if (!mounted) return;
      if (item != null) _populateFromItem(item);
    } finally {
      if (mounted) setState(() => _isLoadingEdit = false);
    }
  }

  void _populateFromItem(Item item) {
    _editItem = item;
    setState(() {
      _category = item.category;
      _isSensitive = item.isSensitive;
      _occurredAt = item.occurredAt;
      _imageUrls = List.from(item.imageUrls);
    });
    _titleCtrl.text = item.title;
    _descCtrl.text = item.description ?? '';
    _locationCtrl.text = item.location;
    _contactCtrl.text = item.contact ?? '';
    _sqCtrl.text = item.secretQuestion ?? '';
    _saCtrl.text = item.secretAnswer ?? '';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) return;
    setState(() {
      _occurredAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_imageUrls.length >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos per post')),
      );
      return;
    }

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final authUser = ref.read(authStateProvider).valueOrNull;
      if (authUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

      final useCase = ref.read(uploadPostPhotosUseCaseProvider);
      final urls = await useCase(
        userId: authUser.uid,
        photoBytes: [bytes],
      );

      if (urls.isNotEmpty && mounted) {
        setState(() {
          _imageUrls = [..._imageUrls, urls.first];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload photo')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto(int index) async {
    setState(() {
      _imageUrls = [
        ..._imageUrls.sublist(0, index),
        ..._imageUrls.sublist(index + 1),
      ];
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    final isFounder = _category == ItemCategory.founder;
    final sensitive = isFounder && _isSensitive;

    final item = Item(
      id: widget.editId ?? '',
      title: _titleCtrl.text.trim(),
      description: sensitive ? null : _descCtrl.text.trim(),
      category: _category,
      status: ItemStatus.active,
      location: _locationCtrl.text.trim(),
      contact: sensitive ? null : _contactCtrl.text.trim(),
      imageUrls: _imageUrls,
      userId: _editItem?.userId ?? authUser.uid,
      createdAt: _editItem?.createdAt ?? DateTime.now(),
      occurredAt: _occurredAt,
      isSensitive: sensitive,
      expiresAt: sensitive
          ? DateTime.now().add(const Duration(days: 14))
          : null,
      secretQuestion:
          isFounder && !sensitive && _sqCtrl.text.trim().isNotEmpty
              ? _sqCtrl.text.trim()
              : null,
      secretAnswer:
          isFounder && !sensitive && _saCtrl.text.trim().isNotEmpty
              ? _saCtrl.text.trim()
              : null,
    );

    if (_isEdit) {
      await ref.read(postFormNotifierProvider.notifier).update(item);
    } else {
      await ref.read(postFormNotifierProvider.notifier).create(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureFlags = ref.watch(featureFlagsProvider);
    final submissionState = ref.watch(postFormNotifierProvider);
    final similarState = ref.watch(similarPostsNotifierProvider);

    ref.listen(postFormNotifierProvider, (prev, state) {
      if ((prev?.isLoading ?? false) && !state.isLoading && !state.hasError) {
        context.pop();
        return;
      }
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save post. Please try again.')),
        );
      }
    });

    if (_isLoadingEdit) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFounder = _category == ItemCategory.founder;
    final sensitive = isFounder && _isSensitive;
    final showSecretQ =
        isFounder && !sensitive && featureFlags.secretQuestionEnabled;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Post' : 'New Post',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: submissionState.isLoading ? null : _submit,
              child: submissionState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kAmber),
                    )
                  : const Text(
                      'POST',
                      style: TextStyle(
                        color: _kAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Category ─────────────────────────────────────
                _CategorySelector(
                  selected: _category,
                  onChanged: (cat) {
                    setState(() {
                      _category = cat;
                      _isSensitive = false;
                    });
                    if (cat == ItemCategory.seeker) {
                      ref
                          .read(similarPostsNotifierProvider.notifier)
                          .clear();
                    } else {
                      ref
                          .read(similarPostsNotifierProvider.notifier)
                          .search(_titleCtrl.text);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ── Title ─────────────────────────────────────────
                _FieldLabel(isFounder ? 'ITEM FOUND' : 'ITEM LOST'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Short description of the item',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required.'
                      : null,
                ),

                // ── Similar Posts ──────────────────────────────────
                if (isFounder) ...[
                  const SizedBox(height: 8),
                  _SimilarPostsPanel(state: similarState),
                ],
                const SizedBox(height: 12),

                // ── Description ───────────────────────────────────
                if (!sensitive) ...[
                  _FieldLabel('DESCRIPTION'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Where and when? Any identifying marks or details?',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Location ──────────────────────────────────────
                _FieldLabel('LOCATION'),
                TextFormField(
                  controller: _locationCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Building, floor, or area',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Location is required.'
                      : null,
                ),
                const SizedBox(height: 12),

                // ── Contact ───────────────────────────────────────
                if (!sensitive) ...[
                  _FieldLabel('CONTACT'),
                  TextFormField(
                    controller: _contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '08x-xxx-xxxx',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Contact number is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Date / Time ───────────────────────────────────
                _FieldLabel(isFounder ? 'DATE FOUND' : 'DATE LOST'),
                _DateTimeTile(value: _occurredAt, onTap: _pickDateTime),
                const SizedBox(height: 12),

                // ── Photos ────────────────────────────────────────
                _FieldLabel('PHOTOS'),
                _PhotosSection(
                  imageUrls: _imageUrls,
                  isUploading: _isUploadingPhoto,
                  onAddPhoto: _pickAndUploadPhoto,
                  onRemovePhoto: _removePhoto,
                  maxPhotos: 3,
                ),
                const SizedBox(height: 12),

                // ── Founder-only options ───────────────────────────
                if (isFounder) ...[
                  _FieldLabel('SENSITIVE ITEM'),
                  _SensitiveSelector(
                    value: _isSensitive,
                    onChanged: (v) => setState(() => _isSensitive = v),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Secret Question (WBS 2.10) ─────────────────────
                if (showSecretQ) ...[
                  _FieldLabel('SECRET QUESTION (optional)'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Only shown to whoever tries to claim this item. Helps verify they know it.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  TextFormField(
                    controller: _sqCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g. What colour is the card sleeve inside?',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _saCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Answer',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                      if (_sqCtrl.text.trim().isNotEmpty &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Answer is required when a secret question is set.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),

                // ── Submit ────────────────────────────────────────
                FilledButton(
                  onPressed: submissionState.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAmber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: submissionState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Post',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onChanged});

  final ItemCategory selected;
  final ValueChanged<ItemCategory> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _CategoryButton(
              label: 'I Found Something',
              category: ItemCategory.founder,
              selected: selected,
              color: _kGreen,
              onTap: () => onChanged(ItemCategory.founder),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CategoryButton(
              label: 'I Lost Something',
              category: ItemCategory.seeker,
              selected: selected,
              color: _kRed,
              onTap: () => onChanged(ItemCategory.seeker),
            ),
          ),
        ],
      );
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.category,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final ItemCategory category;
  final ItemCategory selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = category == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SimilarPostsPanel extends StatelessWidget {
  const _SimilarPostsPanel({required this.state});
  final AsyncValue<List<Item>> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0xFFCA8A04).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: _kAmber),
                  SizedBox(width: 6),
                  Text(
                    'Similar Founder Posts already exist',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${item.title} — ${item.location}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Text(_format(value),
                style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.imageUrls,
    required this.isUploading,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.maxPhotos,
  });

  final List<String> imageUrls;
  final bool isUploading;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final int maxPhotos;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return MouseRegion(
        cursor: isUploading ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isUploading ? null : onAddPhoto,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: isUploading
                  ? const SizedBox(
                      height: 30,
                      width: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Colors.grey.shade400, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          'Add photos (up to $maxPhotos)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            final url = imageUrls[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey.shade400),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onRemovePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kRed,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (imageUrls.length < maxPhotos) ...[
          const SizedBox(height: 8),
          MouseRegion(
            cursor: isUploading ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: isUploading ? null : onAddPhoto,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: Colors.grey.shade400, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'Add more',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SensitiveSelector extends StatelessWidget {
  const _SensitiveSelector({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _SensitiveButton(
              label: 'General Item',
              selected: !value,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SensitiveButton(
              label: 'Sensitive Item',
              selected: value,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      );
}

class _SensitiveButton extends StatelessWidget {
  const _SensitiveButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD97706) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? const Color(0xFFD97706)
                  : Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
