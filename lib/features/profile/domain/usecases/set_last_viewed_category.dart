import 'package:campus_lost_found/features/profile/domain/repositories/preference_repository.dart';

class SetLastViewedCategory {
  final PreferenceRepository _repository;
  const SetLastViewedCategory(this._repository);
  Future<void> call(String? category) => _repository.setLastViewedCategory(category);
}
