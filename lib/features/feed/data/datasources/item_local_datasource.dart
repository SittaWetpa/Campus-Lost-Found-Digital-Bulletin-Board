import 'package:hive/hive.dart';
import 'package:campus_lost_found/features/feed/data/models/item_model.dart';

abstract interface class ItemLocalDatasource {
  List<ItemModel> getCachedFeed();
  ItemModel? getCachedItem(String itemId);
  Future<void> cacheFeed(List<ItemModel> models);
  Future<void> cacheItem(ItemModel model);
  Future<void> removeItem(String itemId);
}

class HiveItemLocalDatasource implements ItemLocalDatasource {
  final Box<Map> _box;
  const HiveItemLocalDatasource(this._box);

  @override
  List<ItemModel> getCachedFeed() {
    final models = _box.values
        .map((raw) => ItemModel.fromHiveMap(raw))
        .toList();
    models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return models;
  }

  @override
  ItemModel? getCachedItem(String itemId) {
    final raw = _box.get(itemId);
    return raw == null ? null : ItemModel.fromHiveMap(raw);
  }

  @override
  Future<void> cacheFeed(List<ItemModel> models) async {
    await _box.clear();
    await _box.putAll({
      for (final m in models) m.id: m.toHiveMap(),
    });
  }

  @override
  Future<void> cacheItem(ItemModel model) async {
    await _box.put(model.id, model.toHiveMap());
  }

  @override
  Future<void> removeItem(String itemId) async {
    await _box.delete(itemId);
  }
}
