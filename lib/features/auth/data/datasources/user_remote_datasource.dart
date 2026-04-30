import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/auth/data/models/user_model.dart';

abstract interface class UserRemoteDatasource {
  Stream<UserModel?> watchUser(String uid);
  Future<UserModel?> getUserById(String uid);
  Future<void> createUser(UserModel model);
  Future<void> updateUser(UserModel model);
}

class FirestoreUserDatasource implements UserRemoteDatasource {
  final FirebaseFirestore _firestore;
  const FirestoreUserDatasource(this._firestore);

  CollectionReference get _users => _firestore.collection('users');

  @override
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  @override
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  @override
  Future<void> createUser(UserModel model) async {
    await _users.doc(model.uid).set({
      ...model.toFirestore(),
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateUser(UserModel model) async {
    await _users.doc(model.uid).update(model.toFirestore());
  }
}