import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

class FirebaseAuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToastLong(
            message: 'The email address is already in use.', isError: true);
      } else {
        showToastLong(message: 'An error occurred: ${e.code}', isError: true);
      }
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      print("Sign-in successful, User: ${credential.user}");
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Sign-in failed with error: ${e.code}");
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        showToastLong(message: 'Invalid email or password.', isError: true);
      } else {
        showToastLong(message: 'An error occurred: ${e.code}', isError: true);
      }
      return null;
    }
  }

  Future<void> authenticateAnonymously() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      try {
        UserCredential userCredential = await auth.signInAnonymously();
        print("Signed in anonymously with UID: ${userCredential.user?.uid}");
        showToastLong(
            message:
                'Signed in anonymously with UID: ${userCredential.user?.uid}',
            isError: true);
      } catch (e) {
        print("Failed to sign in anonymously: $e");
        showToastLong(
            message: 'Failed to sign in anonymously: $e', isError: true);
      }
    }
  }
}
