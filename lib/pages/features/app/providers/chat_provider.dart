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
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _usernameCache = {}; // Cache for username

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

    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([userEmail]),
    });

    fetchChats(userId, userEmail);
  }

  Future<bool> sendInvite(BuildContext context, String chatId, String email,
      String chatName) async {
    try {
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user found with email $email");
        await _showDialog(context, "Error", "No user found with this email.");
        return false;
      }

      final QuerySnapshot existingInvite = await FirebaseFirestore.instance
          .collection('invites')
          .where('chatId', isEqualTo: chatId)
          .where('invitedEmail', isEqualTo: email)
          .get();

      if (existingInvite.docs.isNotEmpty) {
        print("Invite already sent to $email for this chat.");
        await _showDialog(context, "Error",
            "Invite already sent to this user for this chat.");
        return false;
      }

      await FirebaseFirestore.instance.collection('invites').add({
        'chatId': chatId,
        'invitedEmail': email,
        'invitedBy': FirebaseAuth.instance.currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
        'chatName': chatName,
      });

      print("Invite sent to $email");
      await _showDialog(
          context, "Invite Sent", "The invite was successfully sent to $email");
      return true;
    } catch (e) {
      print("Error sending invite: $e");
      await _showDialog(
          context, "Error", "Failed to send invite. Please try again.");
      return false;
    }
  }

  Future<void> _showDialog(
      BuildContext context, String title, String message) async {
    return showDialog<void>(
      context: context,
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
                  await sendInvite(
                      context, chatId, _inviteEmailController.text, chatName);

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
                              Navigator.of(context).pop();
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
                              Navigator.of(context).pop();
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

        final messages = await Future.wait(
            List<Map<String, dynamic>>.from(data['messages'] ?? [])
                .map((msg) async {
          final username = await _getUsername(msg['senderId']);
          return {
            'message': msg['message'],
            'senderId': msg['senderId'],
            'senderEmail': msg['senderEmail'],
            'username': username,
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
      _usernameCache[userId] = username;
      return username;
    } else {
      return 'Unknown';
    }
  }

  Future<void> sendMessage(String problemId, String chatId, String message,
      String senderEmail) async {
    try {
      final newMessage = {
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
        final containerIndex =
            containers.indexWhere((c) => c['containerId'] == chatId);

        if (containerIndex == -1) {
          throw Exception("Container does not exist");
        }

        List<dynamic> messages = containers[containerIndex]['messages'] ?? [];
        messages.add(newMessage);

        containers[containerIndex]['messages'] = messages;

        transaction.update(problemDocRef, {'containers': containers});
      });

      final chatModel = state.firstWhere((chat) => chat.chatId == chatId);
      chatModel.messages.add({
        'message': message,
        'senderEmail': senderEmail,
      });

      state = [
        for (final chat in state)
          if (chat.chatId == chatId)
            ChatModel(
              chatId: chat.chatId,
              chatName: chat.chatName,
              messages: chatModel.messages,
            )
          else
            chat,
      ];
    } catch (e) {
      print("Error sending message: $e");
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(
      String problemId, String containerId) async {
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

      final messages =
          List<Map<String, dynamic>>.from(container['messages'] ?? []);

      final updatedChatModel = ChatModel(
        chatId: containerId,
        chatName: container['containerName'] ?? 'Unknown',
        messages: messages,
      );

      state = [
        for (final chat in state)
          if (chat.chatId == containerId) updatedChatModel else chat,
        if (!state.any((chat) => chat.chatId == containerId)) updatedChatModel,
      ];

      state = [...state];

      return messages;
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

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

  void clearState() {
    state = [];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>(
  (ref) => ChatNotifier(),
);
