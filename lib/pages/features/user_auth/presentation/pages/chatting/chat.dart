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
  TextEditingController _inviteEmailController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Try to fetch the chat model for the given chatId
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
    _inviteEmailController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch chat model from provider
    final chatModel = ref.watch(chatProvider).firstWhere(
        (chat) => chat.chatId == widget.chatId,
        orElse: () => ChatModel(
            chatId: widget.chatId, chatName: 'Unknown', messages: []));

    // If chat does not exist, return a fallback UI
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
              _promptForInviteEmail(context, chatModel.chatName);
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
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chatModel.messages[index],
                          style: AppStyles.titleSmall(
                            color: Theme.of(context).primaryColor,
                          ),
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
                        ref
                            .read(chatProvider.notifier)
                            .sendMessage(widget.chatId, messageController.text);
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
    );
  }

  // Invite email prompt dialog
  Future<void> _promptForInviteEmail(
      BuildContext context, String chatName) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Invite user by email"),
          content: TextField(
            controller: _inviteEmailController,
            decoration: const InputDecoration(hintText: "Email"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black45),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _sendInvite(_inviteEmailController.text, chatName);
                Navigator.of(context).pop();
              },
              child: const Text(
                "Send Invite",
                style: TextStyle(color: Colors.black45),
              ),
            ),
          ],
        );
      },
    );
  }

  // Sending invitation logic
  Future<void> _sendInvite(String email, String chatName) async {
    final FirebaseAuth auth = FirebaseAuth.instance;

    // Send the invite with the current chat name
    await FirebaseFirestore.instance.collection('invites').add({
      'chatId': widget.chatId,
      'invitedEmail': email,
      'invitedBy': auth.currentUser!.email,
      'timestamp': FieldValue.serverTimestamp(),
      'chatName': chatName, // Include the chat name in the invite
    });

    showToast(message: "Invite sent to $email");
  }
}
