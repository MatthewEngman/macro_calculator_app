import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signInAnonymously();
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential> linkWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential?> signInWithGoogle();
  Future<void> signOut();
}
