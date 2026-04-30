import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_lost_found/core/errors/failures.dart';

abstract interface class AuthRemoteDatasource {
  Stream<User?> get authStateChanges;
  Future<User> signIn({required String email, required String password});
  Future<User> signUp({required String email, required String password});
  Future<void> signOut();
}

class FirebaseAuthDatasource implements AuthRemoteDatasource {
  final FirebaseAuth _auth;
  const FirebaseAuthDatasource(this._auth);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapCode(e.code));
    }
  }

  @override
  Future<User> signUp({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mapCode(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _mapCode(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Invalid email or password.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'user-disabled' => 'This account has been disabled.',
        'email-already-in-use' =>
          'An account with this email already exists.',
        'weak-password' => 'Password is too weak.',
        _ => 'An error occurred. Please try again.',
      };
}