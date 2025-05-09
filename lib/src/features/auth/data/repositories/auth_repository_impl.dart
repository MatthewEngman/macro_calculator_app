import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthRepositoryImpl(this._firebaseAuth);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  bool get isUserAnonymous => _firebaseAuth.currentUser?.isAnonymous ?? false;

  @override
  Future<UserCredential> signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  @override
  Future<UserCredential?> linkAnonymousAccountWithGoogle() async {
    try {
      // Check if the user is anonymous
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in',
        );
      }

      if (!user.isAnonymous) {
        throw FirebaseAuthException(
          code: 'not-anonymous',
          message: 'Current user is not anonymous',
        );
      }

      // Store the anonymous user ID for potential data migration
      final String anonymousUserId = user.uid;

      // Trigger the Google authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        // Try to link the anonymous account with the Google credential
        return await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Handle the case where the credential is already associated with a different account
        if (e.code == 'credential-already-in-use') {
          print('Credential already in use, signing in with existing account');

          // Sign out the anonymous user
          await _firebaseAuth.signOut();

          // Sign in with the existing Google account
          final userCredential = await _firebaseAuth.signInWithCredential(
            credential,
          );

          // Trigger data migration between the accounts
          // This will be handled by the authStateListenerProvider
          print(
            'Migrating data from anonymous account: $anonymousUserId to Google account: ${userCredential.user?.uid}',
          );

          return userCredential;
        } else {
          // For other errors, rethrow
          rethrow;
        }
      }
    } catch (e) {
      print('Error linking anonymous account with Google: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    return _firebaseAuth.signOut();
  }
}
