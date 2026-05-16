import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/core/services/sync_metadata_datasource.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_local_datasource.dart';
import 'package:campus_lost_found/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';
import 'package:campus_lost_found/features/auth/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource _datasource;
  final UserLocalDatasource _localDatasource;
  final SyncMetadataDatasource _syncMetadata;

  const UserRepositoryImpl(
    this._datasource,
    this._localDatasource,
    this._syncMetadata,
  );

  @override
  Stream<User?> watchUser(String uid) {
    final cachedModel = _localDatasource.getCachedUser(uid);
    final controller = StreamController<User?>();

    if (cachedModel != null) controller.add(cachedModel.toEntity());

    final sub = _datasource.watchUser(uid).listen(
      (model) async {
        if (model != null) {
          await _localDatasource.cacheUser(model);
          await _syncMetadata.setLastSyncedAt(
              HiveSyncMetadataDatasource.userProfileKey, DateTime.now());
        }
        if (!controller.isClosed) controller.add(model?.toEntity());
      },
      onError: (e) {
        if (!controller.isClosed && cachedModel == null) controller.addError(e);
      },
    );
    controller.onCancel = () {
      sub.cancel();
      controller.close();
    };
    return controller.stream;
  }

  @override
  Future<User?> getUserById(String uid) async {
    try {
      final model = await _datasource.getUserById(uid);
      return model?.toEntity();
    } on FirebaseException catch (_) {
      return _localDatasource.getCachedUser(uid)?.toEntity();
    }
  }

  @override
  Future<void> createUserProfile(User user) async {
    try {
      await _datasource.createUser(UserModel.fromEntity(user));
    } on FirebaseException catch (_) {
      throw const ServerFailure('A server error occurred. Please try again.');
    } catch (_) {
      throw const ServerFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<void> updateUserProfile(User user) async {
    try {
      await _datasource.updateUser(UserModel.fromEntity(user));
    } on FirebaseException catch (_) {
      throw const ServerFailure('A server error occurred. Please try again.');
    } catch (_) {
      throw const ServerFailure('An unexpected error occurred.');
    }
  }
}
