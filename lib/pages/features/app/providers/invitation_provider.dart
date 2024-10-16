import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  InviteNotifier() : super([]) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> acceptInvite(
      String inviteId, String problemId, String userEmail) async {
    try {
      // Instead of using userEmail as document id, perform a query to find the user by email
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        // Get the first user document
        final userDoc = userSnapshot.docs.first;

        // Add the problemId to the user's 'problems' array
        await _firestore.collection('users').doc(userDoc.id).update({
          'problems': FieldValue.arrayUnion([problemId]),
        });

        print("User found and problem added to user's list.");
      } else {
        print("User not found with email: $userEmail");
        throw Exception("User does not exist");
      }

      // Delete the invite after it has been accepted
      await _firestore.collection('invites').doc(inviteId).delete();
      print("Invitation accepted and invite deleted.");
    } catch (e) {
      print("Error accepting invite: $e");
      throw e;
    }
  }

  // Method to delete an invite (used when declined)
  Future<void> deleteInvite(String inviteId) async {
    try {
      await _firestore.collection('invites').doc(inviteId).delete();
      print("Invite deleted.");
    } catch (e) {
      print("Error deleting invite: $e");
    }
  }

  Future<void> fetchInvites(String userEmail) async {
    try {
      print("Fetching invites for email: $userEmail");

      final inviteSnapshot = await _firestore
          .collection('invites')
          .where('invitedEmail', isEqualTo: userEmail)
          .get();

      if (inviteSnapshot.docs.isEmpty) {
        print("No invites found for $userEmail");
      }

      final invites = inviteSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'inviteId': doc.id,
          'problemId': data['problemId'] ?? 'Unknown Problem ID',
          'problemName': data['problemName'] ?? 'Unnamed Problem',
          'invitedBy': data['invitedBy'] ?? 'Unknown',
        };
      }).toList();

      print("Invites fetched: ${invites.length}");
      state = invites;
    } catch (e) {
      print("Error fetching invites: $e");
    }
  }

  void clearState() {
    state = [];
  }
}

final inviteProvider =
    StateNotifierProvider<InviteNotifier, List<Map<String, dynamic>>>(
  (ref) => InviteNotifier(),
);
