import 'package:campus_lost_found/features/profile/domain/entities/user_preferences.dart';
import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';

class SetThemeMode {
  final PreferenceRepository _repository;
  const SetThemeMode(this._repository);
  Future<void> call(AppThemeMode mode) => _repository.setThemeMode(mode);
}
