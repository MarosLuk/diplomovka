import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  InviteNotifier() : super([]);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch invites for the logged-in user
  Future<void> fetchInvites(String userEmail) async {
    final inviteSnapshot = await _firestore
        .collection('invites')
        .where('invitedEmail', isEqualTo: userEmail)
        .get();

    state = inviteSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'inviteId': doc.id, // Store the invite document ID
        'chatId': data['chatId'],
        'chatName': data['chatName'],
        'invitedBy': data['invitedBy'],
      };
    }).toList();
  }

  // Accept invite, add user to chat, and mark invitation as resolved
  Future<void> acceptInvite(
      String inviteId, String chatId, String userId) async {
    final WriteBatch batch = _firestore.batch();

    // Add the user as a participant in the chat
    batch.update(_firestore.collection('chats').doc(chatId), {
      'participants': FieldValue.arrayUnion([userId]),
    });

    // Mark the invite as resolved (you can also choose to delete it)
    batch.update(_firestore.collection('invites').doc(inviteId), {
      'resolved': true,
    });

    // Commit batch
    await batch.commit();

    // Refresh the invites list after accepting
    await fetchInvites(userId);
  }

  // Function to clear state (useful when logging out)
  void clearState() {
    state = [];
  }

  // Function to show popup for accepting or declining invite
  Future<bool> showInvitePopup(BuildContext context, String chatName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Invitation to $chatName'),
            content: Text('Do you want to accept this invitation?'),
            actions: [
              TextButton(
                child: Text(
                  'Decline',
                  style: TextStyle(color: Colors.black45),
                ),
                onPressed: () {
                  Navigator.pop(context, false); // Decline invite
                },
              ),
              TextButton(
                child: Text(
                  'Accept',
                  style: TextStyle(color: Colors.black45),
                ),
                onPressed: () {
                  Navigator.pop(context, true); // Accept invite
                },
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }

  // Function to show a prompt for creating a new chat name
  Future<String?> promptForChatName(BuildContext context) async {
    TextEditingController chatNameController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter chat name'),
          content: TextField(
            controller: chatNameController,
            decoration: const InputDecoration(hintText: "Chat name"),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop(chatNameController.text);
              },
            ),
          ],
        );
      },
    );
  }
}

// Provider for managing state of the InviteNotifier
final inviteProvider =
    StateNotifierProvider<InviteNotifier, List<Map<String, dynamic>>>(
  (ref) => InviteNotifier(),
);
