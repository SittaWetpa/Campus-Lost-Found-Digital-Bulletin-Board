import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:campus_lost_found/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:campus_lost_found/features/feed/data/repositories/item_repository_impl.dart';
import 'package:campus_lost_found/features/feed/domain/repositories/item_repository.dart';

part 'providers.g.dart';

@riverpod
FeedRemoteDatasource feedRemoteDatasource(FeedRemoteDatasourceRef ref) =>
    FeedRemoteDatasourceImpl(FirebaseFirestore.instance);

@riverpod
ItemRepository itemRepository(ItemRepositoryRef ref) =>
    ItemRepositoryImpl(ref.watch(feedRemoteDatasourceProvider));
