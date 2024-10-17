import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final usernameProvider = StateNotifierProvider<UsernameNotifier, String>((ref) {
  return UsernameNotifier();
});

class UsernameNotifier extends StateNotifier<String> {
  UsernameNotifier() : super('Anonymous') {
    fetchUsername();
  }

  Future<void> fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
        if (userDoc.exists) {
          state = userDoc.get('username');
        } else {
          state = 'Anonymous';
        }
      } catch (e) {
        print("Error fetching username: $e");
        state = 'Anonymous';
      }
    } else {
      state = 'Anonymous';
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'username': newUsername});
        state = newUsername;
      } catch (e) {
        print("Error updating username: $e");
      }
    }
  }

  void clearState() {
    state = 'Anonymous';
  }
}
