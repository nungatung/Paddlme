import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave_share/models/user_model.dart';
import 'package:wave_share/services/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth. currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is verified
  bool get isEmailVerified => _auth. currentUser?.emailVerified ?? false;

  // ✅ Sign up with email, password, and username
  Future<UserCredential? > signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // Check if username is available
      final isAvailable = await _userService.isUsernameAvailable(username);
      if (!isAvailable) {
        throw Exception('Username is already taken');
      }

      // Create Firebase Auth user
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email. trim(),
        password: password,
      );

      // Update display name
      await userCredential.user?. updateDisplayName(name);

      // ✅ Create user document in Firestore
      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential. user!.uid,
          email: email. trim(),
          username: username. toLowerCase().trim(),
          name: name,
          createdAt: DateTime.now(),
          isEmailVerified: false,
        );

        await _userService.createUser(userModel);
      }

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e. toString();
    }
  }

  // ✅ Sign in with email OR username
  Future<UserCredential?> signInWithEmailOrUsername({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername.trim();

      // Check if input is username (doesn't contain @)
      if (!email.contains('@')) {
        // Get email from username
        final emailFromUsername = await _userService. getEmailByUsername(email);
        
        if (emailFromUsername == null) {
          throw Exception('Username not found');
        }
        
        email = emailFromUsername;
      }

      // Sign in with email
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Resend verification email
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reload user to check verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email:  email. trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak.  Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email. ';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'An error occurred:  ${e.message}';
    }
  }
}