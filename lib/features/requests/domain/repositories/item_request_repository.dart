import 'dart:io';

import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';

abstract interface class ItemRequestRepository {
  /// Real-time stream of all requests on a given item — Poster's inbox (WBS 2.4).
  Stream<List<ItemRequest>> watchRequestsForItem(String itemId);

  /// Filtered stream of only the requests made by [requesterId] — safe for
  /// Firestore list queries because the .where() filter satisfies the rule
  /// `resource.data.requesterId == request.auth.uid` (WBS 1.3).
  Stream<List<ItemRequest>> watchMyRequestForItem(
      String itemId, String requesterId);

  /// Real-time stream of a single request document — readable by both the
  /// poster (item.userId == auth.uid) and the requester (WBS 1.3).
  Stream<ItemRequest?> watchSingleRequest(String itemId, String requestId);

  /// Submits a new request. Returns the created request with its server-assigned ID.
  Future<ItemRequest> submitRequest(ItemRequest request);

  /// Approves a request: request status → approved, item status → resolved,
  /// item.claimedBy set. Implementation must use a Firestore batch write (WBS 2.4).
  Future<void> approveRequest({
    required String itemId,
    required String requestId,
    required String requesterId,
  });

  /// Rejects a request: request status → rejected (WBS 2.4).
  Future<void> rejectRequest({
    required String itemId,
    required String requestId,
  });

  /// Cancels a request: request status → cancelled. Callable by requester only (WBS 2.4).
  Future<void> cancelRequest({
    required String itemId,
    required String requestId,
  });

  /// Returns true if any pending request exists — used by delete guard (WBS 2.7).
  Future<bool> hasPendingRequests(String itemId);

  /// Uploads a photo for a Found Report. Returns the download URL (WBS 2.4).
  Future<String> uploadRequestPhoto(File imageFile);
}
