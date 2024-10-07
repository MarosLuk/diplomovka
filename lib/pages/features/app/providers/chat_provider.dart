import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatModel {
  String chatId;
  String chatName;
  List<String> messages;

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
          messages: List<String>.from(data['messages'] ?? []),
        );
      }).toList();

      // Update state with the fetched chats
      state = chats;
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }

  // Send a message to a chat, updating Firestore and local state
  Future<void> sendMessage(String chatId, String message) async {
    final chatIndex = state.indexWhere((chat) => chat.chatId == chatId);
    if (chatIndex >= 0) {
      final updatedChat = state[chatIndex];
      final updatedMessages = [...updatedChat.messages, message];

      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({'messages': updatedMessages});

      state = [
        for (final chat in state)
          if (chat.chatId == chatId)
            ChatModel(
              chatId: chat.chatId,
              chatName: chat.chatName,
              messages: updatedMessages,
            )
          else
            chat,
      ];
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
