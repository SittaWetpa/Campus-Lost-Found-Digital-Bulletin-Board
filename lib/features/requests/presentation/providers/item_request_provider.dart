import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:campus_lost_found/features/feed/domain/entities/item.dart';
import 'package:campus_lost_found/features/post/domain/usecases/delete_item_use_case.dart';
import 'package:campus_lost_found/features/post/domain/usecases/update_item_use_case.dart';
import 'package:campus_lost_found/features/post/presentation/providers/post_provider.dart';
import 'package:campus_lost_found/features/requests/data/datasources/item_request_remote_datasource.dart';
import 'package:campus_lost_found/features/requests/data/repositories/item_request_repository_impl.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/approve_request_use_case.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/cancel_request_use_case.dart';
import 'package:campus_lost_found/features/requests/domain/usecases/reject_request_use_case.dart';

part 'item_request_provider.g.dart';

@riverpod
ItemRequestRemoteDatasource itemRequestDatasource(
  ItemRequestDatasourceRef ref,
) {
  return FirestoreItemRequestDatasource(FirebaseFirestore.instance);
}

@riverpod
ItemRequestRepository itemRequestRepository(ItemRequestRepositoryRef ref) {
  return ItemRequestRepositoryImpl(ref.watch(itemRequestDatasourceProvider));
}

@riverpod
Stream<List<ItemRequest>> watchRequestsForItem(
  WatchRequestsForItemRef ref,
  String itemId,
) {
  return ref.watch(itemRequestRepositoryProvider).watchRequestsForItem(itemId);
}

@riverpod
Stream<List<ItemRequest>> watchMyRequestForItem(
  WatchMyRequestForItemRef ref,
  String itemId,
  String requesterId,
) {
  return ref
      .watch(itemRequestRepositoryProvider)
      .watchMyRequestForItem(itemId, requesterId);
}

@riverpod
Stream<ItemRequest?> watchSingleRequest(
  WatchSingleRequestRef ref,
  String itemId,
  String requestId,
) {
  return ref
      .watch(itemRequestRepositoryProvider)
      .watchSingleRequest(itemId, requestId);
}

@riverpod
class ItemDetailActionNotifier extends _$ItemDetailActionNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> approve({
    required String itemId,
    required String requestId,
    required String requesterId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ApproveRequestUseCase(ref.read(itemRequestRepositoryProvider)).call(
        ApproveRequestParams(
          itemId: itemId,
          requestId: requestId,
          requesterId: requesterId,
        ),
      ),
    );
  }

  Future<void> reject({
    required String itemId,
    required String requestId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => RejectRequestUseCase(ref.read(itemRequestRepositoryProvider))
          .call(itemId: itemId, requestId: requestId),
    );
  }

  Future<void> cancel({
    required String itemId,
    required String requestId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => CancelRequestUseCase(ref.read(itemRequestRepositoryProvider))
          .call(itemId: itemId, requestId: requestId),
    );
  }

  Future<void> delete(String itemId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => DeleteItemUseCase(ref.read(postRepositoryProvider)).call(itemId),
    );
  }

  Future<void> resolve(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => UpdateItemUseCase(ref.read(postRepositoryProvider))
          .call(item.copyWith(status: ItemStatus.resolved)),
    );
  }
}
