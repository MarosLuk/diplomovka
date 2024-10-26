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
  final Map<String, String> _usernameCache = {}; // Cache for username

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

  Future<bool> sendInvite(BuildContext context, String chatId, String email,
      String chatName) async {
    try {
      // Check if the user with the provided email exists
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user found with email $email");
        await _showDialog(context, "Error", "No user found with this email.");
        return false; // Email not found
      }

      // Check if an invite for the user and chat already exists
      final QuerySnapshot existingInvite = await FirebaseFirestore.instance
          .collection('invites')
          .where('chatId', isEqualTo: chatId)
          .where('invitedEmail', isEqualTo: email)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        // Invite already exists, show error dialog
        print("Invite already sent to $email for this chat.");
        await _showDialog(context, "Error",
            "Invite already sent to this user for this chat.");
        return false;
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
      await _showDialog(
          context, "Invite Sent", "The invite was successfully sent to $email");
      return true; // Invite sent successfully
    } catch (e) {
      print("Error sending invite: $e");
      await _showDialog(
          context, "Error", "Failed to send invite. Please try again.");
      return false; // Some error occurred
    }
  }

// Function to show dialog (success or error)
  Future<void> _showDialog(
      BuildContext context, String title, String message) async {
    return showDialog<void>(
      context: context, // Replace with your navigator context if necessary
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                      context, chatId, _inviteEmailController.text, chatName);

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
      final userChatsSnapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .get();

      final participantChatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userEmail)
          .get();

      final combinedDocs = [
        ...userChatsSnapshot.docs,
        ...participantChatsSnapshot.docs
      ];

      final chats = await Future.wait(combinedDocs.map((doc) async {
        final data = doc.data();

        // Fetch usernames for all messages
        final messages = await Future.wait(
            List<Map<String, dynamic>>.from(data['messages'] ?? [])
                .map((msg) async {
          final username = await _getUsername(msg['senderId']);
          return {
            'message': msg['message'],
            'senderId': msg['senderId'],
            'senderEmail': msg['senderEmail'],
            'username': username, // Add username to message data
          };
        }).toList());

        return ChatModel(
          chatId: doc.id,
          chatName: data['chatName'],
          messages: messages,
        );
      }).toList());

      state = chats;
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }

  Future<String> _getUsername(String userId) async {
    // Check if the username is already in cache
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }

    // If not, fetch the username from Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final username = userDoc.data()?['username'] ?? 'Unknown';
      _usernameCache[userId] = username; // Cache the username
      return username;
    } else {
      return 'Unknown';
    }
  }

  Future<void> sendMessage(String problemId, String containerId, String message,
      String senderEmail) async {
    try {
      final newMessage = {
        'container': containerId,
        'message': message,
        'senderEmail': senderEmail,
      };

      final problemDocRef = _firestore.collection('problems').doc(problemId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(problemDocRef);
        if (!snapshot.exists) {
          throw Exception("Problem does not exist");
        }

        List<dynamic> containers = snapshot.get('containers') ?? [];
        // Find the container with the matching containerId
        final containerIndex =
            containers.indexWhere((c) => c['containerId'] == containerId);

        if (containerIndex == -1) {
          throw Exception("Container does not exist");
        }

        // Add the new message to the container's messages array
        List<dynamic> messages = containers[containerIndex]['messages'] ?? [];
        messages.add(newMessage);

        // Update the container's messages array
        containers[containerIndex]['messages'] = messages;

        // Commit the changes to the Firestore document
        transaction.update(problemDocRef, {'containers': containers});
      });

      print("Message sent successfully");
    } catch (e) {
      print("Error sending message: $e");
      throw e;
    }
  }

  Future<void> fetchMessages(String problemId, String containerId) async {
    try {
      final problemDoc =
          await _firestore.collection('problems').doc(problemId).get();

      if (!problemDoc.exists) {
        throw Exception("Problem does not exist");
      }

      final containers = problemDoc.data()?['containers'] ?? [];

      final container = containers.firstWhere(
        (c) => c['containerId'] == containerId,
        orElse: () => null,
      );

      if (container == null) {
        throw Exception("Container does not exist");
      }

      final messages = container['messages'] ?? [];

      // Assuming you have a chat model to store messages
      final chatModel = ChatModel(
        chatId: containerId,
        chatName: container['containerName'] ?? 'Unknown',
        messages: List<Map<String, dynamic>>.from(messages),
      );

      // Update state with the fetched messages
      state = [...state, chatModel];
    } catch (e) {
      print("Error fetching messages: $e");
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
