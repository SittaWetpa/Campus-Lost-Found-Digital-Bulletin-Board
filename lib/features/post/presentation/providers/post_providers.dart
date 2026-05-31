import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/core/services/storage_repository.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/usecases/create_item_use_case.dart';
import 'package:campus_lost_found/features/post/domain/usecases/update_item_use_case.dart';
import 'package:campus_lost_found/features/post/domain/usecases/upload_post_photos_use_case.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';

part 'post_providers.g.dart';

@riverpod
StorageRepository storageRepository(_) {
  return _FirebaseStorageRepository(FirebaseStorage.instance);
}

@riverpod
UploadPostPhotosUseCase uploadPostPhotosUseCase(ref) {
  return UploadPostPhotosUseCase(ref.watch(storageRepositoryProvider));
}

class _FirebaseStorageRepository implements StorageRepository {
  final FirebaseStorage _storage;
  _FirebaseStorageRepository(this._storage);

  @override
  Future<String> uploadBytes(List<int> bytes, String storagePath) async {
    final ref = _storage.ref(storagePath);
    final uint8bytes = Uint8List.fromList(bytes);
    await ref.putData(uint8bytes);
    return ref.getDownloadURL();
  }

  @override
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}

@riverpod
class PostFormNotifier extends _$PostFormNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> create(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await CreateItemUseCase(ref.read(postRepositoryProvider)).call(item);
    });
  }

  Future<void> update(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await UpdateItemUseCase(ref.read(postRepositoryProvider)).call(item);
    });
  }
}
