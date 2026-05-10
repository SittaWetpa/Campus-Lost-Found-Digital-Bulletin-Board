import 'package:hive/hive.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';

abstract interface class UserLocalDatasource {
  UserModel? getCachedUser(String uid);
  Future<void> cacheUser(UserModel model);
}

class HiveUserLocalDatasource implements UserLocalDatasource {
  final Box<Map> _box;
  const HiveUserLocalDatasource(this._box);

  @override
  UserModel? getCachedUser(String uid) {
    final raw = _box.get(uid);
    return raw == null ? null : UserModel.fromHiveMap(raw);
  }

  @override
  Future<void> cacheUser(UserModel model) async {
    await _box.put(model.uid, model.toHiveMap());
  }
}
