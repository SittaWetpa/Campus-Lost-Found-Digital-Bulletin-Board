import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_lost_found/features/notifications/data/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationServiceImpl(
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
  ),
);
