import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/presentation/providers/item_provider.dart';
import 'package:campus_lost_found/features/post/data/repositories/post_repository_impl.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

part 'post_provider.g.dart';

@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  return PostRepositoryImpl(ref.watch(itemDatasourceProvider));
}
