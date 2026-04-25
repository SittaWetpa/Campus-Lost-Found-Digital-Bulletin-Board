import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_lost_found/features/auth/domain/entities/user.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String studentId;
  final String telephone;
  final String? avatarUrl;
  final bool emailVerified;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.telephone,
    this.avatarUrl,
    required this.emailVerified,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      studentId: data['studentId'] as String,
      telephone: data['telephone'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory UserModel.fromEntity(User user) => UserModel(
        uid: user.uid,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        studentId: user.studentId,
        telephone: user.telephone,
        avatarUrl: user.avatarUrl,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'studentId': studentId,
        'telephone': telephone,
        'avatarUrl': avatarUrl,
        'emailVerified': emailVerified,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  User toEntity() => User(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        telephone: telephone,
        avatarUrl: avatarUrl,
        emailVerified: emailVerified,
        createdAt: createdAt,
      );
}