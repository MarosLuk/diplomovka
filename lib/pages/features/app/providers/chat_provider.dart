import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class ChatModel {
  String chatId;
  String chatName;
  List<Map<String, dynamic>> messages;

  ChatModel({
    required this.chatId,
    required this.chatName,
    required this.messages,
  });
}

class ChatNotifier extends StateNotifier<List<ChatModel>> {
  ChatNotifier() : super([]) {
    // Disable persistence for Firestore to avoid using offline data
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat, directly reflecting in Firestore without any offline checks
  Future<String> createNewChat(String chatName, String userId) async {
    final newChat = {
      'chatName': chatName,
      'userId': userId,
      'messages': [],
    };

    final chatRef = await _firestore.collection('chats').add(newChat);

    final newChatModel =
        ChatModel(chatId: chatRef.id, chatName: chatName, messages: []);
    state = [...state, newChatModel];

    return chatRef.id;
  }

  Future<void> acceptInvite(String chatId) async {
    final userEmail = FirebaseAuth.instance.currentUser!.email!;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Add the user as a participant in the chat
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([userEmail]),
    });

    // Fetch both user's own chats and chats where the user is a participant
    fetchChats(userId, userEmail);
  }

  Future<bool> sendInvite(String chatId, String email, String chatName) async {
    try {
      // Check if the user with the provided email exists
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user found with email $email");
        return false; // Email not found
      }

      // Send the invite with the current chat name if the email exists
      await FirebaseFirestore.instance.collection('invites').add({
        'chatId': chatId,
        'invitedEmail': email,
        'invitedBy': FirebaseAuth.instance.currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
        'chatName': chatName, // Include the chat name in the invite
      });

      print("Invite sent to $email");
      return true; // Invite sent successfully
    } catch (e) {
      print("Error sending invite: $e");
      return false; // Some error occurred
    }
  }

  // Prompt for invite email - moved from ChatPage
  Future<void> promptForInviteEmail(
      BuildContext context, String chatId, String chatName) async {
    TextEditingController _inviteEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: Text(
            "Invite user by email",
            style: AppStyles.titleMedium(
                color: Theme.of(context).colorScheme.primary),
          ),
          content: TextField(
            controller: _inviteEmailController,
            decoration: InputDecoration(
              hintText: "Email",
              hintStyle: AppStyles.labelLarge(
                  color: Theme.of(context).colorScheme.primary),
            ),
            style: AppStyles.labelLarge(
                color: Theme.of(context).colorScheme.primary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: AppStyles.labelLarge(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Try sending the invite
                  await sendInvite(
                      chatId, _inviteEmailController.text, chatName);

                  // Show success dialog after the invite has been sent
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Invite Sent'),
                        content: Text(
                            'The invite was successfully sent to ${_inviteEmailController.text}'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text('OK',
                                style: TextStyle(
                                  color: Colors.black45,
                                )),
                          ),
                        ],
                      );
                    },
                  );
                } catch (e) {
                  // Show error dialog if something goes wrong
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content:
                            Text('Failed to send invite. Please try again.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text('OK',
                                style: TextStyle(
                                  color: Colors.black45,
                                )),
                          ),
                        ],
                      );
                    },
                  );
                } finally {
                  // Close the invite email dialog after action
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                "Send Invite",
                style: AppStyles.labelLarge(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // Fetch both user's own chats and chats where the user is a participant
  Future<void> fetchChats(String userId, String userEmail) async {
    try {
      // Fetch chats created by the user
      final userChatsSnapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .get();

      // Fetch chats where the user is a participant
      final participantChatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userEmail)
          .get();

      // Combine both sets of chats
      final combinedDocs = [
        ...userChatsSnapshot.docs,
        ...participantChatsSnapshot.docs
      ];

      final chats = combinedDocs.map((doc) {
        final data = doc.data();
        return ChatModel(
          chatId: doc.id,
          chatName: data['chatName'],
          messages: List<Map<String, dynamic>>.from(data['messages'] ?? []),
        );
      }).toList();

      // Update state with the fetched chats
      state = chats;
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }

  Future<void> sendMessage(String chatId, String message) async {
    try {
      final userId =
          FirebaseAuth.instance.currentUser!.uid; // Get sender's user ID
      final senderEmail =
          FirebaseAuth.instance.currentUser!.email; // Get sender's email

      final newMessage = {
        'message': message,
        'senderId': userId,
        'senderEmail': senderEmail,
      };

      print("Attempting to send message: $newMessage");

      // Directly update the chat document using arrayUnion to add the message
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'messages': FieldValue.arrayUnion([newMessage]),
      });

      print("Message sent successfully");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Update the chat name in Firestore and local state
  Future<void> updateChatName(String chatId, String newChatName) async {
    await _firestore.collection('chats').doc(chatId).update({
      'chatName': newChatName,
    });

    state = [
      for (final chat in state)
        if (chat.chatId == chatId)
          ChatModel(
            chatId: chat.chatId,
            chatName: newChatName,
            messages: chat.messages,
          )
        else
          chat,
    ];
  }

  // Clear state when the user logs out or no longer needs the chat list
  void clearState() {
    state = [];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>(
  (ref) => ChatNotifier(),
);
