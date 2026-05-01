import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/features/post/data/datasources/post_remote_datasource.dart';
import 'package:campus_lost_found/features/post/data/repositories/post_repository_impl.dart';
import 'package:campus_lost_found/features/post/domain/repositories/post_repository.dart';

part 'providers.g.dart';

@riverpod
PostRemoteDatasource postRemoteDatasource(PostRemoteDatasourceRef ref) =>
    PostRemoteDatasourceImpl(FirebaseFirestore.instance);

@riverpod
PostRepository postRepository(PostRepositoryRef ref) =>
    PostRepositoryImpl(ref.watch(postRemoteDatasourceProvider));
