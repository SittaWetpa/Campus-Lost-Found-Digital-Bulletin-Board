import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:campus_lost_found/features/feed/data/datasources/item_local_datasource.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';

ItemModel _model({
  required String id,
  required DateTime createdAt,
  String status = 'active',
}) =>
    ItemModel(
      id: id,
      title: 'Item $id',
      description: 'desc',
      category: 'seeker',
      status: status,
      location: 'Library',
      contact: '080',
      imageUrls: const [],
      userId: 'u1',
      createdAt: createdAt,
      occurredAt: createdAt,
    );

void main() {
  late Directory tmpDir;
  late Box<Map> box;
  late HiveItemLocalDatasource ds;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<Map>('items_box_test');
    ds = HiveItemLocalDatasource(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('items_box_test');
    await tmpDir.delete(recursive: true);
  });

  test('01 getCachedFeed() returns empty list on cold start', () {
    expect(ds.getCachedFeed(), isEmpty);
  });

  test('02 cacheFeed() persists items and re-orders by createdAt descending',
      () async {
    final older = _model(id: 'a', createdAt: DateTime(2026, 1, 1));
    final newer = _model(id: 'b', createdAt: DateTime(2026, 6, 1));
    await ds.cacheFeed([older, newer]);

    final result = ds.getCachedFeed();
    expect(result.length, 2);
    expect(result.first.id, 'b'); // newer first
    expect(result.last.id, 'a');
  });

  test('03 cacheFeed() replaces previous cache entirely', () async {
    await ds.cacheFeed([_model(id: 'old', createdAt: DateTime(2026, 1, 1))]);
    await ds.cacheFeed([_model(id: 'new', createdAt: DateTime(2026, 6, 1))]);

    final result = ds.getCachedFeed();
    expect(result.length, 1);
    expect(result.first.id, 'new');
  });

  test('04 cacheItem() upserts a single item', () async {
    final m = _model(id: 'x', createdAt: DateTime(2026, 3, 1));
    await ds.cacheItem(m);

    final found = ds.getCachedItem('x');
    expect(found, isNotNull);
    expect(found!.title, 'Item x');

    // upsert — update title via a new model with same id
    final updated = ItemModel(
      id: 'x',
      title: 'Updated',
      description: '',
      category: 'seeker',
      status: 'active',
      location: '',
      contact: '',
      imageUrls: const [],
      userId: 'u1',
      createdAt: DateTime(2026, 3, 1),
      occurredAt: DateTime(2026, 3, 1),
    );
    await ds.cacheItem(updated);
    expect(ds.getCachedItem('x')!.title, 'Updated');
  });

  test('05 removeItem() removes exactly one item', () async {
    await ds.cacheFeed([
      _model(id: 'keep', createdAt: DateTime(2026, 1, 1)),
      _model(id: 'gone', createdAt: DateTime(2026, 2, 1)),
    ]);

    await ds.removeItem('gone');

    expect(ds.getCachedItem('gone'), isNull);
    expect(ds.getCachedItem('keep'), isNotNull);
  });

  test('06 round-trip toHiveMap/fromHiveMap preserves all fields', () async {
    final original = ItemModel(
      id: 'rt',
      title: 'Title',
      description: 'Desc',
      category: 'founder',
      status: 'active',
      location: 'Gate A',
      contact: '081',
      imageUrls: const ['img1.jpg', 'img2.jpg'],
      userId: 'user1',
      source: 'qr_walk_in',
      isSensitive: true,
      createdAt: DateTime(2026, 5, 1, 10, 0),
      occurredAt: DateTime(2026, 4, 30, 8, 0),
      editedAt: DateTime(2026, 5, 2, 12, 0),
      expiresAt: DateTime(2026, 6, 1, 0, 0),
      claimedBy: 'claimer',
      secretQuestion: 'What color?',
      secretAnswer: 'Blue',
      posterName: 'Alice',
      posterAvatarUrl: 'https://example.com/avatar.jpg',
    );

    await ds.cacheItem(original);
    final retrieved = ds.getCachedItem('rt')!;

    expect(retrieved.id, original.id);
    expect(retrieved.title, original.title);
    expect(retrieved.description, original.description);
    expect(retrieved.category, original.category);
    expect(retrieved.status, original.status);
    expect(retrieved.location, original.location);
    expect(retrieved.contact, original.contact);
    expect(retrieved.imageUrls, original.imageUrls);
    expect(retrieved.userId, original.userId);
    expect(retrieved.source, original.source);
    expect(retrieved.isSensitive, original.isSensitive);
    expect(retrieved.createdAt, original.createdAt);
    expect(retrieved.occurredAt, original.occurredAt);
    expect(retrieved.editedAt, original.editedAt);
    expect(retrieved.expiresAt, original.expiresAt);
    expect(retrieved.claimedBy, original.claimedBy);
    expect(retrieved.secretQuestion, original.secretQuestion);
    expect(retrieved.secretAnswer, original.secretAnswer);
    expect(retrieved.posterName, original.posterName);
    expect(retrieved.posterAvatarUrl, original.posterAvatarUrl);
  });

  test('07 round-trip preserves nullable DateTime fields as null', () async {
    final m = _model(id: 'nulls', createdAt: DateTime(2026, 1, 1));
    await ds.cacheItem(m);
    final retrieved = ds.getCachedItem('nulls')!;

    expect(retrieved.editedAt, isNull);
    expect(retrieved.expiresAt, isNull);
    expect(retrieved.claimedBy, isNull);
    expect(retrieved.secretQuestion, isNull);
    expect(retrieved.secretAnswer, isNull);
    expect(retrieved.posterName, isNull);
    expect(retrieved.posterAvatarUrl, isNull);
  });
}
