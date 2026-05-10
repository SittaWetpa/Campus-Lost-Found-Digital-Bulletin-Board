// WBS 1.4 — UploadPostPhotosUseCase: 3-photo cap and path convention.

import 'package:campus_lost_found/core/services/storage_repository.dart';
import 'package:campus_lost_found/features/post/domain/usecases/upload_post_photos_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageRepository extends Mock implements StorageRepository {}

void main() {
  late _MockStorageRepository storage;
  late UploadPostPhotosUseCase useCase;

  setUp(() {
    storage = _MockStorageRepository();
    useCase = UploadPostPhotosUseCase(storage);
    when(() => storage.uploadBytes(any(), any())).thenAnswer(
      (inv) async {
        final path = inv.positionalArguments[1] as String;
        return 'https://storage.example.com/$path';
      },
    );
  });

  test('0 photos → returns empty list, never calls storage', () async {
    final urls = await useCase(userId: 'u1', photoBytes: const []);

    expect(urls, isEmpty);
    verifyNever(() => storage.uploadBytes(any(), any()));
  });

  test('1 photo → returns 1 URL', () async {
    final urls = await useCase(
      userId: 'u1',
      photoBytes: [
        [1, 2, 3],
      ],
    );

    expect(urls, hasLength(1));
    verify(() => storage.uploadBytes(any(), any())).called(1);
  });

  test('3 photos → returns 3 URLs in input order', () async {
    final urls = await useCase(
      userId: 'u1',
      photoBytes: [
        [1],
        [2],
        [3],
      ],
    );

    expect(urls, hasLength(3));
    // Each URL contains the items/{userId}/ prefix and a -<index>.jpg suffix.
    for (var i = 0; i < urls.length; i++) {
      expect(urls[i], contains('items/u1/'));
      expect(urls[i], endsWith('-$i.jpg'));
    }
  });

  test('4 photos → throws ArgumentError, never calls storage', () async {
    await expectLater(
      useCase(
        userId: 'u1',
        photoBytes: [
          [1],
          [2],
          [3],
          [4],
        ],
      ),
      throwsArgumentError,
    );
    verifyNever(() => storage.uploadBytes(any(), any()));
  });

  test('path convention: items/{userId}/{millis}-{index}.jpg', () async {
    await useCase(
      userId: 'user-42',
      photoBytes: [
        [1],
        [2],
      ],
    );

    final captured = verify(
      () => storage.uploadBytes(any(), captureAny()),
    ).captured;
    expect(captured, hasLength(2));
    final p0 = captured[0] as String;
    final p1 = captured[1] as String;

    expect(p0, startsWith('items/user-42/'));
    expect(p0, endsWith('-0.jpg'));
    expect(p1, startsWith('items/user-42/'));
    expect(p1, endsWith('-1.jpg'));
  });
}
