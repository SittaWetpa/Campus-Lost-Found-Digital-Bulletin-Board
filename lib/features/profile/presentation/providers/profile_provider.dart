import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/profile/data/datasources/preference_local_datasource.dart';
import 'package:campus_lost_found/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:campus_lost_found/features/profile/data/repositories/preference_repository_impl.dart';
import 'package:campus_lost_found/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/profile_repository.dart';
import 'package:campus_lost_found/features/profile/domain/usecases/get_user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/usecases/set_notifications_enabled.dart';
import 'package:campus_lost_found/features/profile/domain/usecases/update_profile.dart';
import 'package:campus_lost_found/features/profile/domain/usecases/upload_avatar.dart';

part 'profile_provider.g.dart';

// ── Datasource providers ─────────────────────────────────────────────────────

@riverpod
ProfileRemoteDatasource profileRemoteDatasource(ProfileRemoteDatasourceRef ref) {
  return FirebaseProfileDatasource(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
}

@riverpod
PreferenceLocalDatasource preferenceLocalDatasource(
    PreferenceLocalDatasourceRef ref) {
  return SharedPreferencesDatasource();
}

// ── Repository providers ─────────────────────────────────────────────────────

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDatasourceProvider));
}

@riverpod
PreferenceRepository preferenceRepository(PreferenceRepositoryRef ref) {
  return PreferenceRepositoryImpl(
      ref.watch(preferenceLocalDatasourceProvider));
}

// ── Edit Profile — saves text fields ────────────────────────────────────────

@riverpod
class EditProfileNotifier extends _$EditProfileNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save({
    required String uid,
    required String firstName,
    required String lastName,
    required String telephone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await UpdateProfile(ref.read(profileRepositoryProvider)).call(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        telephone: telephone,
      );
    });
  }
}

// ── Upload Avatar — separate notifier for independent loading state ──────────

@riverpod
class UploadAvatarNotifier extends _$UploadAvatarNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> upload({
    required String uid,
    required List<int> bytes,
    required String extension,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await UploadAvatar(ref.read(profileRepositoryProvider)).call(
        uid: uid,
        bytes: bytes,
        extension: extension,
      );
    });
  }
}

// ── User Preferences — one-shot read (shared_preferences is not a stream) ───

@riverpod
Future<UserPreferences> userPreferences(UserPreferencesRef ref) {
  return GetUserPreferences(ref.watch(preferenceRepositoryProvider)).call();
}

// ── Preferences Notifier — notifications toggle ──────────────────────────────

@riverpod
class PreferencesNotifier extends _$PreferencesNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> setNotificationsEnabled({required bool value}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SetNotificationsEnabled(ref.read(preferenceRepositoryProvider))
          .call(value: value);
      ref.invalidate(userPreferencesProvider); // re-fetch after write
    });
  }
}
