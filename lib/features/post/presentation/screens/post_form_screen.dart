import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:campus_lost_found/core/services/feature_flag_service.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_lost_found/features/auth/presentation/providers/user_provider.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_providers.dart';
import 'package:campus_lost_found/features/post/presentation/providers/similar_items_provider.dart';
import 'package:campus_lost_found/features/post/presentation/widgets/category_picker.dart';
import 'package:campus_lost_found/features/post/presentation/widgets/similar_posts_panel.dart';
import 'package:campus_lost_found/shared/widgets/confirm_dialog.dart';

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
  ItemTaxonomy? _itemTaxonomy;
  bool _itemCategoryError = false;
  bool _isSensitive = false;
  DateTime _occurredAt = DateTime.now();
  List<String> _imageUrls = const [];

  Item? _editItem;
  bool _isLoadingEdit = false;
  bool _isUploadingPhoto = false;

  bool _useMyNumber = true;
  String _myTelephone = '';

  // Photo Safety Guard: tracks previous SQ value to detect empty→non-empty.
  String _sqLastValue = '';

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
    _sqCtrl.addListener(_onSecretQuestionChanged);
    if (_isEdit) {
      _isLoadingEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditItem());
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _initContactFromProfile());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    _sqCtrl
      ..removeListener(_onSecretQuestionChanged)
      ..dispose();
    _saCtrl.dispose();
    super.dispose();
  }

  // Photo Safety Guard, Case 2: SQ transitions empty→non-empty with photos present.
  void _onSecretQuestionChanged() {
    final current = _sqCtrl.text;
    final wasEmpty = _sqLastValue.trim().isEmpty;
    final nowFilled = current.trim().isNotEmpty;
    _sqLastValue = current;
    if (wasEmpty && nowFilled && _imageUrls.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final confirmed = await _showPhotoSafetyDialog(isReview: true);
        if (!mounted) return;
        if (confirmed != true) _sqCtrl.clear();
      });
    }
  }

  Future<void> _initContactFromProfile() async {
    final user = await ref.read(currentUserProvider.future);
    final tel = user?.telephone ?? '';
    if (!mounted) return;
    setState(() {
      _myTelephone = tel;
      _useMyNumber = tel.isNotEmpty;
    });
    if (tel.isNotEmpty) _contactCtrl.text = tel;
  }

  void _onContactSourceChanged(bool useMyNumber) {
    setState(() => _useMyNumber = useMyNumber);
    if (useMyNumber) {
      _contactCtrl.text = _myTelephone;
    } else {
      _contactCtrl.clear();
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
      _itemTaxonomy = item.itemTaxonomy;
      _isSensitive = item.isSensitive;
      _occurredAt = item.occurredAt ?? DateTime.now();
      _imageUrls = List.from(item.imageUrls);
    });
    _titleCtrl.text = item.title;
    _descCtrl.text = item.description;
    _locationCtrl.text = item.location;
    _contactCtrl.text = item.contact;
    _sqLastValue = item.secretQuestion ?? '';
    _sqCtrl.text = item.secretQuestion ?? '';
    _saCtrl.text = item.secretAnswer ?? '';

    final user = ref.read(currentUserProvider).valueOrNull;
    final tel = user?.telephone ?? '';
    setState(() {
      _myTelephone = tel;
      _useMyNumber = tel.isNotEmpty && item.contact == tel;
    });
  }

  Future<bool> _showPhotoSafetyDialog({required bool isReview}) {
    return showConfirmDialog(
      context: context,
      title: 'Photo Safety',
      body: isReview
          ? 'You attached photos before setting the Secret Question. Make '
              'sure the photos do NOT reveal the answer — anyone with a '
              'photo could bypass verification. Confirm or remove the '
              'photos before proceeding.'
          : 'Make sure your photos do NOT show the answer to your Secret '
              'Question. Anyone with a photo could bypass verification.',
      confirmLabel: 'I understand',
      cancelLabel: 'Cancel',
    );
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

    // Photo Safety Guard, Case 1: gate add-photo behind confirmation if SQ filled.
    if (_sqCtrl.text.trim().isNotEmpty) {
      final confirmed = await _showPhotoSafetyDialog(isReview: false);
      if (confirmed != true) return;
      if (!mounted) return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
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
      final urls = await useCase(userId: authUser.uid, photoBytes: [bytes]);

      if (urls.isNotEmpty && mounted) {
        setState(() => _imageUrls = [..._imageUrls, urls.first]);
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

  void _onCategoryChanged(ItemTaxonomy taxonomy) {
    setState(() {
      _itemTaxonomy = taxonomy;
      _itemCategoryError = false;
      _titleCtrl.clear();
    });
    if (_category == ItemCategory.seeker) {
      ref.read(similarItemsNotifierProvider.notifier).load(taxonomy);
    } else {
      ref.read(similarItemsNotifierProvider.notifier).clear();
    }
  }

  Future<void> _submit() async {
    final isFounder = _category == ItemCategory.founder;
    final sensitive = isFounder && _isSensitive;

    // Run form validation first so all field errors show at once.
    final formValid = _formKey.currentState!.validate();

    // Category picker is outside the Form; validate it separately.
    if (!sensitive && _itemTaxonomy == null) {
      setState(() => _itemCategoryError = true);
      return;
    }
    if (!formValid) return;

    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    final profile = await ref.read(currentUserProvider.future);
    if (!mounted) return;
    final embeddedPosterName = profile != null
        ? '${profile.firstName} ${profile.lastName}'.trim()
        : null;
    final embeddedPosterAvatarUrl = profile?.avatarUrl;

    final item = Item(
      id: widget.editId ?? '',
      title: _titleCtrl.text.trim(),
      description: sensitive ? '' : _descCtrl.text.trim(),
      category: _category,
      status: ItemStatus.active,
      location: _locationCtrl.text.trim(),
      contact: sensitive ? '' : _contactCtrl.text.trim(),
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
      posterName: _editItem?.posterName ?? embeddedPosterName,
      posterAvatarUrl: _editItem?.posterAvatarUrl ?? embeddedPosterAvatarUrl,
      itemTaxonomy: _itemTaxonomy ?? ItemTaxonomy.other,
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
    final similarState = ref.watch(similarItemsNotifierProvider);

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
                // ── 1. Post type ────────────────────────────────────
                _CategorySelector(
                  selected: _category,
                  onChanged: (cat) {
                    setState(() {
                      _category = cat;
                      _isSensitive = false;
                    });
                    if (_itemTaxonomy != null) {
                      if (cat == ItemCategory.seeker) {
                        ref
                            .read(similarItemsNotifierProvider.notifier)
                            .load(_itemTaxonomy!);
                      } else {
                        ref
                            .read(similarItemsNotifierProvider.notifier)
                            .clear();
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ── 2. Sensitive selector (Founder only) ────────────
                if (isFounder && featureFlags.sensitiveItemEnabled) ...[
                  _FieldLabel('ITEM TYPE'),
                  _SensitiveSelector(
                    value: _isSensitive,
                    onChanged: (v) => setState(() => _isSensitive = v),
                  ),
                  const SizedBox(height: 8),
                  _SensitiveExplanationBox(isSensitive: _isSensitive),
                  const SizedBox(height: 12),
                ],

                // ── 3. Category picker (hidden when sensitive) ───────
                if (!sensitive) ...[
                  _FieldLabel('ITEM CATEGORY'),
                  CategoryPicker(
                    selected: _itemTaxonomy,
                    onChanged: _onCategoryChanged,
                    errorText: _itemCategoryError
                        ? 'Please select a category.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // ── 4. Quick-pick chips ──────────────────────────────
                if (!sensitive && _itemTaxonomy != null) ...[
                  _QuickPickChips(
                    taxonomy: _itemTaxonomy!,
                    currentTitle: _titleCtrl.text,
                    onChipTap: (chip) => setState(() {
                      _titleCtrl.text =
                          _titleCtrl.text == chip ? '' : chip;
                    }),
                  ),
                  const SizedBox(height: 4),
                ],

                // ── 5. Title ─────────────────────────────────────────
                _FieldLabel(isFounder ? 'ITEM FOUND' : 'ITEM LOST'),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _itemTaxonomy != null
                        ? (_category == ItemCategory.seeker
                            ? 'e.g. Lost ${_itemTaxonomy!.displayNameEn.toLowerCase()}'
                            : _itemTaxonomy!.titlePlaceholder)
                        : 'Short description of the item',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required.'
                      : null,
                ),

                // ── 6. Similar posts (Seeker + category selected) ────
                if (!isFounder && _itemTaxonomy != null)
                  SimilarPostsPanel(state: similarState),
                const SizedBox(height: 12),

                // ── 7. Description ───────────────────────────────────
                if (!sensitive) ...[
                  _FieldLabel('DESCRIPTION'),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _itemTaxonomy?.descPlaceholder ??
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

                // ── 8. Location ──────────────────────────────────────
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

                // ── 9. Contact ───────────────────────────────────────
                if (!sensitive) ...[
                  _FieldLabel('CONTACT'),
                  if (_myTelephone.isNotEmpty) ...[
                    _ContactSourceSelector(
                      useMyNumber: _useMyNumber,
                      onChanged: _onContactSourceChanged,
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextFormField(
                    controller: _contactCtrl,
                    keyboardType: TextInputType.phone,
                    readOnly: _useMyNumber && _myTelephone.isNotEmpty,
                    decoration: InputDecoration(
                      hintText: '08x-xxx-xxxx',
                      filled: true,
                      fillColor: (_useMyNumber && _myTelephone.isNotEmpty)
                          ? const Color(0xFFF3F4F6)
                          : Colors.white,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Contact number is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── 10. Date / Time ──────────────────────────────────
                _FieldLabel(isFounder ? 'DATE FOUND' : 'DATE LOST'),
                _DateTimeTile(value: _occurredAt, onTap: _pickDateTime),
                const SizedBox(height: 12),

                // ── 11. Photos ───────────────────────────────────────
                _FieldLabel('PHOTOS'),
                _PhotosRow(
                  imageUrls: _imageUrls,
                  isUploading: _isUploadingPhoto,
                  onAddPhoto: _pickAndUploadPhoto,
                  onRemovePhoto: _removePhoto,
                ),
                // Photo safety hint for Founder + non-sensitive + secret Q enabled
                if (isFounder && !sensitive && featureFlags.secretQuestionEnabled) ...[
                  const SizedBox(height: 8),
                  _PhotoSafetyHint(),
                ],
                const SizedBox(height: 12),

                // ── 12. Secret Question ──────────────────────────────
                if (showSecretQ) ...[
                  _SecretQuestionSection(
                    sqCtrl: _sqCtrl,
                    saCtrl: _saCtrl,
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),

                // ── Submit ───────────────────────────────────────────
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
              subtitle: 'Founder Post',
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
              subtitle: 'Seeker Post',
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
    required this.subtitle,
    required this.category,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final ItemCategory category;
  final ItemCategory selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = category == selected;
    return Semantics(
      label: '$label — $subtitle',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensitiveSelector extends StatelessWidget {
  const _SensitiveSelector({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _SensitiveButton(
              label: 'General Item',
              subtitle: 'Standard claim flow',
              selected: !value,
              selectedColor: _kGreen,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SensitiveButton(
              label: 'Sensitive Item',
              subtitle: 'Office pickup only',
              selected: value,
              selectedColor: const Color(0xFFD97706),
              onTap: () => onChanged(true),
            ),
          ),
        ],
      );
}

class _SensitiveButton extends StatelessWidget {
  const _SensitiveButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label — $subtitle',
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? selectedColor : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : Colors.grey.shade700,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? selectedColor.withValues(alpha: 0.8)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensitiveExplanationBox extends StatelessWidget {
  const _SensitiveExplanationBox({required this.isSensitive});
  final bool isSensitive;

  @override
  Widget build(BuildContext context) {
    final bg = isSensitive
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFF9FAFB);
    final border = isSensitive
        ? const Color(0xFFE0AA40)
        : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      child: Text(
        isSensitive
            ? 'Sensitive items (ID cards, bank cards, passports, keys, official documents) are handled through the Security Office. Contact details and description are hidden, and the post auto-expires in 14 days.'
            : 'General items go through the standard claim flow — the seeker contacts you directly in-app. Use Sensitive Item if what you found contains personal data or grants access.',
        style: TextStyle(
          fontSize: 12.5,
          height: 1.5,
          color: isSensitive
              ? const Color(0xFF92400E)
              : Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _QuickPickChips extends StatelessWidget {
  const _QuickPickChips({
    required this.taxonomy,
    required this.currentTitle,
    required this.onChipTap,
  });

  final ItemTaxonomy taxonomy;
  final String currentTitle;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final chips = taxonomy.chips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK PICK',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips.map((chip) {
            final isActive = currentTitle == chip;
            return Semantics(
              label: chip,
              button: true,
              selected: isActive,
              child: GestureDetector(
                onTap: () => onChipTap(chip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFEF3C7)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? _kAmber
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    chip,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF92400E)
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Date and time: ${_format(value)}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              Text(_format(value), style: const TextStyle(fontSize: 15)),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
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

// Photo section: full-width button when empty; thumbnail row + small add
// button when photos are present. Matches the original UX contract that
// tests depend on (the "Add photos (up to 3)" large button is detectable).
class _PhotosRow extends StatelessWidget {
  const _PhotosRow({
    required this.imageUrls,
    required this.isUploading,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<String> imageUrls;
  final bool isUploading;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Semantics(
        label: 'Add photos (up to 3)',
        button: true,
        child: MouseRegion(
          cursor: isUploading
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
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
                            'Add photos (up to 3)',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...imageUrls.asMap().entries.map(
          (e) => _PhotoThumb(
            url: e.value,
            onRemove: () => onRemovePhoto(e.key),
          ),
        ),
        if (imageUrls.length < 3)
          Semantics(
            label: 'Add more photos',
            button: true,
            child: MouseRegion(
              cursor: isUploading
                  ? SystemMouseCursors.forbidden
                  : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isUploading ? null : onAddPhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    color: Colors.transparent,
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
                              Icon(Icons.add_a_photo_outlined,
                                  size: 20, color: Colors.grey.shade500),
                              const SizedBox(height: 3),
                              Text(
                                'Add more',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image,
                    color: Colors.grey.shade400),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: Semantics(
              label: 'Remove photo',
              button: true,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xCC000000),
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSafetyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined,
              size: 14, color: Color(0xFF15803D)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'If you plan to set a secret question, make sure no photo reveals the answer — avoid close-ups showing a label, serial number, or any detail your question asks about.',
              style: TextStyle(
                  fontSize: 12, height: 1.5, color: Color(0xFF166534)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecretQuestionSection extends StatelessWidget {
  const _SecretQuestionSection({
    required this.sqCtrl,
    required this.saCtrl,
  });

  final TextEditingController sqCtrl;
  final TextEditingController saCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kAmber.withValues(alpha: 0.5),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 18, color: _kAmber),
              const SizedBox(width: 6),
              const Text(
                'SECRET QUESTION (optional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ask something only the real owner would know. Visitors must answer to submit a claim.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: sqCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. What colour is the card sleeve inside?',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: saCtrl,
            decoration: const InputDecoration(
              hintText: 'Expected answer (only you will see this)',
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (v) {
              if (sqCtrl.text.trim().isNotEmpty &&
                  (v == null || v.trim().isEmpty)) {
                return 'Answer is required when a secret question is set.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _ContactSourceSelector extends StatelessWidget {
  const _ContactSourceSelector({
    required this.useMyNumber,
    required this.onChanged,
  });

  final bool useMyNumber;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _ContactSourceButton(
              label: 'Use my number',
              selected: useMyNumber,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ContactSourceButton(
              label: 'Use different',
              selected: !useMyNumber,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      );
}

class _ContactSourceButton extends StatelessWidget {
  const _ContactSourceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kAmber : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? _kAmber : Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
