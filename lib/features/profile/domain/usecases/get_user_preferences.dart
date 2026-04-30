import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';

class GetUserPreferences {
  final PreferenceRepository _repository;
  const GetUserPreferences(this._repository);

  Future<UserPreferences> call() => _repository.getUserPreferences();
}
