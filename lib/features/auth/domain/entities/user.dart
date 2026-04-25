class User {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String studentId;
  final String telephone;
  final String? avatarUrl;
  final bool emailVerified;
  final DateTime createdAt;

  const User({
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
}