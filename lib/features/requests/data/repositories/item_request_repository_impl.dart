import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:campus_lost_found/core/errors/failures.dart';
import 'package:campus_lost_found/features/requests/data/datasources/item_request_remote_datasource.dart';
import 'package:campus_lost_found/features/requests/data/models/item_request_model.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';
import 'package:campus_lost_found/features/requests/domain/repositories/item_request_repository.dart';

class ItemRequestRepositoryImpl implements ItemRequestRepository {
  final ItemRequestRemoteDatasource _datasource;
  const ItemRequestRepositoryImpl(this._datasource);

  @override
  Stream<List<ItemRequest>> watchRequestsForItem(String itemId) {
    return _datasource
        .watchRequestsForItem(itemId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<ItemRequest>> watchMyRequestForItem(
      String itemId, String requesterId) {
    return _datasource
        .watchMyRequestForItem(itemId, requesterId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<ItemRequest?> watchSingleRequest(String itemId, String requestId) {
    return _datasource
        .watchSingleRequest(itemId, requestId)
        .map((m) => m?.toEntity());
  }

  @override
  Future<ItemRequest> submitRequest(ItemRequest request) async {
    try {
      final model =
          await _datasource.submitRequest(ItemRequestModel.fromEntity(request));
      return model.toEntity();
    } on FirebaseException catch (e) {
      throw RequestFailure(e.message ?? 'Failed to submit request.');
    } catch (_) {
      throw const RequestFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<void> approveRequest({
    required String itemId,
    required String requestId,
    required String requesterId,
  }) async {
    try {
      await _datasource.approveRequest(
        itemId: itemId,
        requestId: requestId,
        requesterId: requesterId,
      );
    } on FirebaseException catch (e) {
      throw RequestFailure(e.message ?? 'Failed to approve request.');
    } catch (_) {
      throw const RequestFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<void> rejectRequest({
    required String itemId,
    required String requestId,
  }) async {
    try {
      await _datasource.rejectRequest(itemId: itemId, requestId: requestId);
    } on FirebaseException catch (e) {
      throw RequestFailure(e.message ?? 'Failed to reject request.');
    } catch (_) {
      throw const RequestFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<void> cancelRequest({
    required String itemId,
    required String requestId,
  }) async {
    try {
      await _datasource.cancelRequest(itemId: itemId, requestId: requestId);
    } on FirebaseException catch (e) {
      throw RequestFailure(e.message ?? 'Failed to cancel request.');
    } catch (_) {
      throw const RequestFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<bool> hasPendingRequests(String itemId) async {
    try {
      return await _datasource.hasPendingRequests(itemId);
    } on FirebaseException catch (e) {
      throw RequestFailure(e.message ?? 'Failed to check pending requests.');
    } catch (_) {
      throw const RequestFailure('An unexpected error occurred.');
    }
  }

  @override
  Future<String> uploadRequestPhoto(File imageFile) async {
    try {
      return await _datasource.uploadRequestPhoto(imageFile);
    } on FirebaseException catch (e) {
      throw RequestFailure(e.message ?? 'Failed to upload photo.');
    } catch (_) {
      throw const RequestFailure('An unexpected error occurred.');
    }
  }
}
