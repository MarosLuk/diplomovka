// firebase_auth_services.dart
import 'package:diplomovka/pages/features/user_auth/secureStorage/secureStorageService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Simulated token durations.
  final Duration accessTokenDuration = const Duration(days: 5);
  final Duration refreshTokenDuration = const Duration(days: 5);

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = credential.user;
      if (user != null) {
        await _saveSimulatedTokens();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToastLong(
            message: 'The email address is already in use.', isError: true);
      } else {
        showToastLong(message: 'An error occurred: ${e.code}', isError: true);
      }
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = credential.user;
      if (user != null) {
        await _saveSimulatedTokens();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToastLong(message: 'Invalid email or password.', isError: true);
      } else {
        showToastLong(message: 'An error occurred: ${e.code}', isError: true);
      }
      return null;
    }
  }

  /// Simulate token generation and save them.
  Future<void> _saveSimulatedTokens() async {
    // Generate dummy token strings.
    final String dummyAccessToken =
        "dummy_access_token_${DateTime.now().millisecondsSinceEpoch}";
    final String dummyRefreshToken =
        "dummy_refresh_token_${DateTime.now().millisecondsSinceEpoch}";

    // Set token expirations.
    final DateTime accessTokenExpiry = DateTime.now().add(accessTokenDuration);
    final DateTime refreshTokenExpiry =
        DateTime.now().add(refreshTokenDuration);

    await SecureStorageService().saveTokens(
      dummyAccessToken,
      dummyRefreshToken,
      accessTokenExpiresAt: accessTokenExpiry,
      refreshTokenExpiresAt: refreshTokenExpiry,
    );
  }

  Future<void> authenticateAnonymously() async {
    if (_auth.currentUser == null) {
      try {
        UserCredential userCredential = await _auth.signInAnonymously();
        showToastLong(
            message:
                'Signed in anonymously with UID: ${userCredential.user?.uid}',
            isError: false);
        await _saveSimulatedTokens();
      } catch (e) {
        showToastLong(
            message: 'Failed to sign in anonymously: $e', isError: true);
      }
    }
  }
}
