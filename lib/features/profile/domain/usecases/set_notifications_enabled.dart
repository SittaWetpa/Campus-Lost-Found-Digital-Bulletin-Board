import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';

class SetNotificationsEnabled {
  final PreferenceRepository _repository;
  const SetNotificationsEnabled(this._repository);

  Future<void> call({required bool value}) =>
      _repository.setNotificationsEnabled(value: value);
}
