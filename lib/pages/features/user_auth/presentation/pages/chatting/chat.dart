import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _isEditingName = false;
  TextEditingController _chatNameController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";
  bool _shouldScrollToBottom = true; // Flag to manage scroll behavior
  bool _showScrollToBottomButton = false; // To control arrow visibility

  @override
  void initState() {
    super.initState();

    final chatModel = ref.read(chatProvider).firstWhere(
        (chat) => chat.chatId == widget.chatId,
        orElse: () => ChatModel(
            chatId: widget.chatId, chatName: 'Unknown', messages: []));

    if (chatModel != null) {
      _chatNameController.text = chatModel.chatName;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showToast(message: 'Chat does not exist or has been deleted');
        Navigator.pop(context);
      });
    }

    // Scroll to bottom when chat is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _scrollController.addListener(_onScroll);
  }

  // Handle scroll events
  void _onScroll() {
    final distanceFromBottom = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;

    if (distanceFromBottom >= 500) {
      _shouldScrollToBottom = false; // If user is not near the bottom
      setState(() {
        _showScrollToBottomButton = true; // Show the arrow button
      });
    }

    if (distanceFromBottom > 0 && distanceFromBottom < 500) {
      _shouldScrollToBottom = false; // If user is not near the bottom
      setState(() {
        _showScrollToBottomButton = false; // Show the arrow button
      });
    }

    if (distanceFromBottom == 0) {
      _shouldScrollToBottom = false; // If user is not near the bottom
      setState(() {
        _showScrollToBottomButton = false; // Show the arrow button
      });
    }
  }

  // Smoothly scroll to the bottom of the ListView
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
            milliseconds: 300), // Adjust the duration to your preference
        curve: Curves
            .easeOut, // You can adjust the curve to control the scroll behavior
      );
    }
  }

  @override
  void dispose() {
    _chatNameController.dispose();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatModel = ref.watch(chatProvider).firstWhere(
        (chat) => chat.chatId == widget.chatId,
        orElse: () => ChatModel(
            chatId: widget.chatId, chatName: 'Unknown', messages: []));

    // Scroll to bottom if new message arrives and user is already at the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldScrollToBottom) {
        _scrollToBottom();
      }
    });

    if (chatModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat not found'),
        ),
        body: const Center(
          child: Text('This chat does not exist or has been deleted.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _isEditingName
            ? TextField(
                controller: _chatNameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter chat name",
                  border: InputBorder.none,
                ),
                onSubmitted: (newChatName) {
                  ref
                      .read(chatProvider.notifier)
                      .updateChatName(widget.chatId, newChatName);
                  setState(() {
                    _isEditingName = false;
                  });
                },
              )
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingName = true;
                  });
                },
                child: Text(
                  chatModel.chatName,
                  style: AppStyles.headLineMedium(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: Theme.of(context).primaryColor),
            onPressed: () {
              ref.read(chatProvider.notifier).promptForInviteEmail(
                  context, widget.chatId, chatModel.chatName);
            },
          ),
        ],
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple[600]!, Colors.deepPurple[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: chatModel.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatModel.messages[index];
                        final senderUsername = message['username'] ?? 'Unknown';
                        final isCurrentUser =
                            message['senderEmail'] == currentUserEmail;

                        // Create a unique key based on message content and timestamp
                        final messageKey = UniqueKey();

                        return Align(
                          key: messageKey, // Ensure unique key for each message
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            children: [
                              Text(
                                senderUsername, // Display the username
                                style: AppStyles.labelSmall(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue[400]
                                      : Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message[
                                          'message'], // Display the message text
                                      style: AppStyles.titleSmall(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                            decoration: InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            ref.read(chatProvider.notifier).sendMessage(
                                widget.chatId, messageController.text);
                            messageController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showScrollToBottomButton) // Conditionally show the button
            Positioned(
              bottom: 70,
              right: 20,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
