import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

class ProfileNotifier extends StateNotifier<void> {
  ProfileNotifier() : super(null);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<Map<String, String>> fetchUserData() async {
    try {
      if (_user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_user!.uid).get();

        if (userDoc.exists) {
          return {
            'username': userDoc.get('username'),
            'email': _user!.email!,
          };
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      showToastLong(message: "Error fetching user data", isError: true);
    }
    return {};
  }

  Future<void> updateUserProfile(
      {required String newUsername,
      required String newEmail,
      required String newPassword}) async {
    try {
      QuerySnapshot emailCheck = await _firestore
          .collection('users')
          .where('email', isEqualTo: newEmail)
          .get();

      if (emailCheck.docs.isNotEmpty && _user!.email != newEmail) {
        showToastLong(
            message: "Email already exists in the database.", isError: true);
        return;
      }

      if (newEmail != _user!.email) {
        await _user!.updateEmail(newEmail);
      }

      if (newPassword.isNotEmpty) {
        await _user!.updatePassword(newPassword);
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        'username': newUsername,
        'email': newEmail,
      });

      showToast(message: "Profile updated successfully", isError: false);
    } catch (e) {
      showToastLong(message: "Error updating profile: $e", isError: true);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, void>(
  (ref) => ProfileNotifier(),
);
