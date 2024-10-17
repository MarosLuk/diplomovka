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
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
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
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
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
      } catch (e) {
        print("Failed to sign in anonymously: $e");
      }
    }
  }
}
