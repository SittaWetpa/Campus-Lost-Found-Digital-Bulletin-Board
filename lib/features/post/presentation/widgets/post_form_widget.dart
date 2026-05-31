import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:campus_lost_found/features/feed/domain/entities/item.dart';

const _maxPhotos = 3;

/// Immutable value object passed to [PostFormWidget.onSave].
class ItemFormData {
  final String title;
  final String description;
  final ItemCategory category;
  final String location;
  final DateTime? occurredAt;
  final String contact;
  final List<String> keptImageUrls;
  final List<String> removedImageUrls;
  final List<XFile> newImageFiles;

  const ItemFormData({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.contact,
    this.occurredAt,
    this.keptImageUrls = const [],
    this.removedImageUrls = const [],
    this.newImageFiles = const [],
  });
}

/// Shared form used by WBS 2.6 (edit) and WBS 1.4 (create).
///
/// Pass [initialItem] to pre-populate fields for edit mode.
/// In edit mode the category field is read-only.
class PostFormWidget extends StatefulWidget {
  final Item? initialItem;
  final bool isSaving;
  final void Function(ItemFormData) onSave;

  const PostFormWidget({
    super.key,
    this.initialItem,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<PostFormWidget> createState() => _PostFormWidgetState();
}

class _PostFormWidgetState extends State<PostFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactController;

  late ItemCategory _category;
  DateTime? _occurredAt;

  late List<String> _keptImageUrls;
  final List<String> _removedImageUrls = [];
  final List<XFile> _newImageFiles = [];
  final List<Uint8List> _newImageBytes = [];

  bool get _isEditMode => widget.initialItem != null;
  int get _totalPhotos => _keptImageUrls.length + _newImageFiles.length;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController =
        TextEditingController(text: item?.description ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _contactController = TextEditingController(text: item?.contact ?? '');
    _category = item?.category ?? ItemCategory.seeker;
    _occurredAt = item?.occurredAt;
    _keptImageUrls = List<String>.from(item?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxPhotos - _totalPhotos;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      limit: remaining,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      setState(() {
        _newImageFiles.add(file);
        _newImageBytes.add(bytes);
      });
    }
  }

  void _removeKeptImage(int index) {
    setState(() {
      _removedImageUrls.add(_keptImageUrls[index]);
      _keptImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
      _newImageBytes.removeAt(index);
    });
  }

  Future<void> _pickOccurredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _occurredAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(ItemFormData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      location: _locationController.text.trim(),
      occurredAt: _occurredAt,
      contact: _contactController.text.trim(),
      keptImageUrls: List.unmodifiable(_keptImageUrls),
      removedImageUrls: List.unmodifiable(_removedImageUrls),
      newImageFiles: List.unmodifiable(_newImageFiles),
    ));
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FieldLabel('TITLE'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(hintText: 'e.g. Blue water bottle'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required.' : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('CATEGORY'),
          const SizedBox(height: 6),
          _isEditMode
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(_category == ItemCategory.seeker
                        ? 'Seeker Post'
                        : 'Founder Post'),
                  ),
                )
              : SegmentedButton<ItemCategory>(
                  segments: const [
                    ButtonSegment(
                      value: ItemCategory.seeker,
                      label: Text('Seeker Post'),
                      icon: Icon(Icons.search),
                    ),
                    ButtonSegment(
                      value: ItemCategory.founder,
                      label: Text('Founder Post'),
                      icon: Icon(Icons.inventory_2_outlined),
                    ),
                  ],
                  selected: {_category},
                  onSelectionChanged: (s) =>
                      setState(() => _category = s.first),
                ),
          const SizedBox(height: 16),
          _FieldLabel('DESCRIPTION'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Describe the item in detail',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Description is required.'
                : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('LOCATION'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _locationController,
            textCapitalization: TextCapitalization.sentences,
            decoration:
                const InputDecoration(hintText: 'e.g. Library 2nd floor'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Location is required.'
                : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('DATE & TIME (OPTIONAL)'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickOccurredAt,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _occurredAt != null
                        ? _formatDateTime(_occurredAt!)
                        : 'Select date & time',
                    style: TextStyle(
                      color: _occurredAt != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('CONTACT'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(hintText: 'Phone number or Line ID'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Contact is required.'
                : null,
          ),
          const SizedBox(height: 16),
          _FieldLabel('PHOTOS (max $_maxPhotos)'),
          const SizedBox(height: 8),
          _PhotoGrid(
            keptUrls: _keptImageUrls,
            newBytes: _newImageBytes,
            totalPhotos: _totalPhotos,
            maxPhotos: _maxPhotos,
            onRemoveKept: _removeKeptImage,
            onRemoveNew: _removeNewImage,
            onAdd: _pickImages,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.isSaving ? null : _submit,
            child: widget.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> keptUrls;
  final List<Uint8List> newBytes;
  final int totalPhotos;
  final int maxPhotos;
  final void Function(int) onRemoveKept;
  final void Function(int) onRemoveNew;
  final VoidCallback onAdd;

  const _PhotoGrid({
    required this.keptUrls,
    required this.newBytes,
    required this.totalPhotos,
    required this.maxPhotos,
    required this.onRemoveKept,
    required this.onRemoveNew,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < keptUrls.length; i++)
          _PhotoThumbnail(
            child: CachedNetworkImage(imageUrl: keptUrls[i], fit: BoxFit.cover),
            onRemove: () => onRemoveKept(i),
          ),
        for (int i = 0; i < newBytes.length; i++)
          _PhotoThumbnail(
            child: Image.memory(newBytes[i], fit: BoxFit.cover),
            onRemove: () => onRemoveNew(i),
          ),
        if (totalPhotos < maxPhotos)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _PhotoThumbnail({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 80, height: 80, child: child),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
