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
      final problemDoc =
          await _firestore.collection('problems').doc(problemId).get();

      if (problemDoc.exists) {
        await _firestore.collection('problems').doc(problemId).update({
          'collaborators': FieldValue.arrayUnion([userEmail]),
        });

        await _firestore.collection('invites').doc(inviteId).delete();
        print(
            "Invitation accepted, user added as collaborator, and invite deleted.");
      } else {
        throw Exception("Problem does not exist");
      }
    } catch (e) {
      print("Error accepting invite: $e");
      throw e;
    }
  }

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
      final inviteSnapshot = await _firestore
          .collection('invites')
          .where('invitedEmail', isEqualTo: userEmail)
          .get();

      final invites = inviteSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'inviteId': doc.id,
          'problemId': data['problemId'] ?? 'Unknown Problem ID',
          'problemName': data['problemName'] ?? 'Unnamed Problem',
          'invitedBy': data['invitedBy'] ?? 'Unknown',
        };
      }).toList();

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
