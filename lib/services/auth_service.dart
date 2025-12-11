import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes (Used for a future redirect check)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Sign Up (with Email Verification)
  Future<String?> signUp({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Send the verification email immediately
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the Firebase specific error
    }
  }

  // 2. Login
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // We rely on email verification being done externally for simplicity.
      // If verification is mandatory for access, you would add a check here.

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 3. Forgot Password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 4. Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}