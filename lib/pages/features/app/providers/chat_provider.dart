import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a ChatModel to handle both the chat name and messages
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

// Define a ChatNotifier to manage the chat name and messages
class ChatNotifier extends StateNotifier<List<ChatModel>> {
  ChatNotifier() : super([]) {
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to fetch all chats from Firebase
  Future<void> fetchChats(String userId) async {
    try {
      final chatSnapshot = await _firestore
          .collection('chats')
          .where('userId',
              isEqualTo: userId) // Fetch only the chats that belong to the user
          .get(const GetOptions(
              source: Source.cache)); // First try to get from cache

      final chats = chatSnapshot.docs.map((doc) {
        final data = doc.data();
        return ChatModel(
          chatId: doc.id,
          chatName: data['chatName'],
          messages: List<String>.from(data['messages'] ?? []),
        );
      }).toList();

      state = chats;
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }

  // Method to create a new chat, only if the user is online
  Future<String> createNewChat(String chatName, String userId) async {
    if (await _isOnline()) {
      final newChat = {
        'chatName': chatName,
        'userId': userId, // Store the userId with each chat
        'messages': [],
      };
      final chatRef = await _firestore.collection('chats').add(newChat);

      final newChatModel =
          ChatModel(chatId: chatRef.id, chatName: chatName, messages: []);
      state = [...state, newChatModel];

      return chatRef.id; // Return the new chat's ID
    } else {
      throw Exception("You must be online to create a new chat");
    }
  }

  // Method to send a message and update Firebase
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

  // Method to update chat name in Firebase
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

  // Helper method to check if the user is online
  Future<bool> _isOnline() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;
  }
}

// Define a StateNotifierProvider for the chat
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatModel>>(
  (ref) => ChatNotifier(),
);
