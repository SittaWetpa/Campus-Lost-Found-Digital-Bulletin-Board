import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_metadata_datasource.g.dart';

abstract interface class SyncMetadataDatasource {
  DateTime? getLastSyncedAt(String key);
  Future<void> setLastSyncedAt(String key, DateTime value);
}

class HiveSyncMetadataDatasource implements SyncMetadataDatasource {
  static const itemsFeedKey = 'items_last_synced_at';
  static const userProfileKey = 'user_last_synced_at';

  final Box<dynamic> _box;
  const HiveSyncMetadataDatasource(this._box);

  @override
  DateTime? getLastSyncedAt(String key) {
    final raw = _box.get(key) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  @override
  Future<void> setLastSyncedAt(String key, DateTime value) async {
    await _box.put(key, value.toIso8601String());
  }
}

@riverpod
SyncMetadataDatasource syncMetadata(SyncMetadataRef ref) {
  return HiveSyncMetadataDatasource(Hive.box<dynamic>('sync_metadata_box'));
}

@riverpod
DateTime? itemsFeedLastSyncedAt(ItemsFeedLastSyncedAtRef ref) {
  return ref
      .watch(syncMetadataProvider)
      .getLastSyncedAt(HiveSyncMetadataDatasource.itemsFeedKey);
}
