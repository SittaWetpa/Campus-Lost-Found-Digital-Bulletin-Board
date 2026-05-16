import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class NotificationService {
  Future<void> requestPermission();
  Future<void> registerToken(String uid);
  Future<void> unregisterToken(String uid);
}

class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  const NotificationServiceImpl({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
  })  : _messaging = messaging,
        _firestore = firestore;

  @override
  Future<void> requestPermission() async {
    await _messaging.requestPermission();
  }

  @override
  Future<void> registerToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.doc('users/$uid').update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  @override
  Future<void> unregisterToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _firestore.doc('users/$uid').update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}
