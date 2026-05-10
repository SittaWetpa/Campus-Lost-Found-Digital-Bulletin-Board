import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';

void main() {
  late Directory tmpDir;
  late Box<dynamic> box;
  late HiveSyncMetadataDatasource ds;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('hive_sync_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<dynamic>('sync_meta_test');
    ds = HiveSyncMetadataDatasource(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('sync_meta_test');
    await tmpDir.delete(recursive: true);
  });

  group('HiveSyncMetadataDatasource — WBS 2.11', () {
    test('01 getLastSyncedAt() returns null on cold start', () {
      expect(
        ds.getLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey),
        isNull,
      );
    });

    test(
        '02 setLastSyncedAt() + getLastSyncedAt() round-trip preserves DateTime',
        () async {
      final ts = DateTime(2026, 5, 10, 12, 0, 0);
      await ds.setLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey, ts);

      final result =
          ds.getLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey);
      expect(result, equals(ts));
    });

    test('03 itemsFeedKey and userProfileKey are independent slots', () async {
      final feedTime = DateTime(2026, 5, 10, 10, 0);
      final userTime = DateTime(2026, 5, 10, 11, 0);

      await ds.setLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey, feedTime);
      await ds.setLastSyncedAt(
          HiveSyncMetadataDatasource.userProfileKey, userTime);

      expect(
        ds.getLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey),
        equals(feedTime),
      );
      expect(
        ds.getLastSyncedAt(HiveSyncMetadataDatasource.userProfileKey),
        equals(userTime),
      );
    });

    test('04 setLastSyncedAt() overwrites the previous value for the same key',
        () async {
      await ds.setLastSyncedAt(
          HiveSyncMetadataDatasource.itemsFeedKey, DateTime(2026, 5, 1));
      await ds.setLastSyncedAt(
          HiveSyncMetadataDatasource.itemsFeedKey, DateTime(2026, 5, 10));

      expect(
        ds.getLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey),
        equals(DateTime(2026, 5, 10)),
      );
    });
  });
}
