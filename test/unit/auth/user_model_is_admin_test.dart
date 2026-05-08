// WBS 2.18 — UserModel.isAdmin serialization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_lost_found/features/auth/data/models/user_model.dart';

Map<String, dynamic> _baseDoc({bool? isAdmin}) {
  final data = <String, dynamic>{
    'email': 'sitta@mail.kmutt.ac.th',
    'firstName': 'Sitta',
    'lastName': 'Wetpa',
    'studentId': '67000000',
    'telephone': '0812345678',
    'emailVerified': true,
    'createdAt': Timestamp.now(),
  };
  if (isAdmin != null) data['isAdmin'] = isAdmin;
  return data;
}

Future<DocumentSnapshot> _writeAndRead(
  FakeFirebaseFirestore firestore,
  Map<String, dynamic> data,
) async {
  await firestore.collection('users').doc('uid-1').set(data);
  return firestore.collection('users').doc('uid-1').get();
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('UserModel.fromFirestore — WBS 2.18 isAdmin', () {
    test('reads isAdmin == true from the user document', () async {
      final doc = await _writeAndRead(firestore, _baseDoc(isAdmin: true));
      final model = UserModel.fromFirestore(doc);
      expect(model.isAdmin, isTrue);
    });

    test('reads isAdmin == false from the user document', () async {
      final doc = await _writeAndRead(firestore, _baseDoc(isAdmin: false));
      final model = UserModel.fromFirestore(doc);
      expect(model.isAdmin, isFalse);
    });

    test('defaults isAdmin to false when the field is missing', () async {
      final doc = await _writeAndRead(firestore, _baseDoc());
      final model = UserModel.fromFirestore(doc);
      expect(model.isAdmin, isFalse);
    });

    test('toEntity carries isAdmin through to the User entity', () async {
      final doc = await _writeAndRead(firestore, _baseDoc(isAdmin: true));
      final user = UserModel.fromFirestore(doc).toEntity();
      expect(user.isAdmin, isTrue);
    });
  });
}
