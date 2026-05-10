import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_service.g.dart';

@riverpod
StorageService storageService(StorageServiceRef ref) {
  return StorageService(FirebaseStorage.instance);
}

class StorageService {
  final FirebaseStorage _storage;
  const StorageService(this._storage);

  // Uses readAsBytes so it works on both Android and Web.
  Future<String> uploadImage(XFile file, String folder) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('$folder/$name');
    final bytes = await file.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: file.mimeType));
    return ref.getDownloadURL();
  }

  Future<void> deleteImageByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Already deleted or URL invalid — safe to ignore.
    }
  }
}
