import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signInAnonymously();
  Future<UserCredential?> signInWithGoogle();
  Future<UserCredential?> linkAnonymousAccountWithGoogle();
  bool get isUserAnonymous;
  Future<void> signOut();
}
