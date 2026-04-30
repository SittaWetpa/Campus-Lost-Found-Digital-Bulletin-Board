import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/profile_repository.dart';

class UploadAvatar {
  final ProfileRepository _repository;
  const UploadAvatar(this._repository);

  Future<void> call({
    required String uid,
    required List<int> bytes,
    required String extension,
  }) {
    if (bytes.length > 2097152) {
      throw const ProfileFailure('Image must be 2 MB or smaller.');
    }
    final ext = extension.toLowerCase();
    if (ext != 'jpg' && ext != 'png') {
      throw const ProfileFailure('Only JPG and PNG images are supported.');
    }
    return _repository.uploadAvatar(
      uid: uid,
      bytes: bytes,
      extension: ext,
    );
  }
}
