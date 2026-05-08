import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/requests/domain/entities/item_request.dart';

class ItemRequestModel {
  final String id;
  final String itemId;
  final String requesterId;
  final String requesterName;
  final String requesterContact;
  final String studentId;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? message;
  final String? visitorAnswer;
  final String? photoUrl;

  const ItemRequestModel({
    required this.id,
    required this.itemId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterContact,
    required this.studentId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.message,
    this.visitorAnswer,
    this.photoUrl,
  });

  factory ItemRequestModel.fromMap(String id, Map<String, dynamic> data) =>
      ItemRequestModel(
        id: id,
        itemId: data['itemId'] as String? ?? '',
        requesterId: data['requesterId'] as String,
        requesterName: data['requesterName'] as String? ?? '',
        requesterContact: data['requesterContact'] as String? ?? '',
        studentId: data['studentId'] as String? ?? '',
        type: data['type'] as String,
        status: data['status'] as String,
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        message: data['message'] as String?,
        visitorAnswer: data['visitorAnswer'] as String?,
        photoUrl: data['photoUrl'] as String?,
      );

  factory ItemRequestModel.fromFirestore(DocumentSnapshot doc) =>
      ItemRequestModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory ItemRequestModel.fromEntity(ItemRequest entity) => ItemRequestModel(
        id: entity.id,
        itemId: entity.itemId,
        requesterId: entity.requesterId,
        requesterName: entity.requesterName,
        requesterContact: entity.requesterContact,
        studentId: entity.studentId,
        type: entity.type.name,
        status: entity.status.name,
        createdAt: entity.createdAt,
        message: entity.message,
        visitorAnswer: entity.visitorAnswer,
        photoUrl: entity.photoUrl,
      );

  Map<String, dynamic> toFirestore() => {
        'itemId': itemId,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterContact': requesterContact,
        'studentId': studentId,
        'type': type,
        'status': status,
        if (message != null) 'message': message,
        if (visitorAnswer != null) 'visitorAnswer': visitorAnswer,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

  ItemRequest toEntity() => ItemRequest(
        id: id,
        itemId: itemId,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterContact: requesterContact,
        studentId: studentId,
        type: RequestType.fromString(type),
        status: RequestStatus.fromString(status),
        createdAt: createdAt,
        message: message,
        visitorAnswer: visitorAnswer,
        photoUrl: photoUrl,
      );
}
