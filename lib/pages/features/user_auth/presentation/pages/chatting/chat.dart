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
  }

  @override
  void dispose() {
    _chatNameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatModel = ref.watch(chatProvider).firstWhere(
        (chat) => chat.chatId == widget.chatId,
        orElse: () => ChatModel(
            chatId: widget.chatId, chatName: 'Unknown', messages: []));

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
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: chatModel.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatModel.messages[index];
                    final senderEmail = message['senderEmail'] ??
                        'Unknown'; // Get sender's email

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderEmail,
                              style: AppStyles.titleSmall(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              message['message'], // Display the message text
                              style: AppStyles.titleSmall(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                        print("Send button clicked");
                        ref
                            .read(chatProvider.notifier)
                            .sendMessage(widget.chatId, messageController.text);
                        print("Message send function called");
                        messageController.clear();
                        print("Message controller cleared");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
