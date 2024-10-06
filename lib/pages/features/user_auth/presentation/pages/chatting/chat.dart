import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _isEditingName = false; // Track whether the chat name is being edited
  TextEditingController _chatNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final chatModel = ref
        .read(chatProvider)
        .firstWhere((chat) => chat.chatId == widget.chatId);
    _chatNameController.text = chatModel.chatName;
  }

  @override
  void dispose() {
    _chatNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatModel = ref
        .watch(chatProvider)
        .firstWhere((chat) => chat.chatId == widget.chatId);
    final TextEditingController messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: _isEditingName
            ? TextField(
                controller: _chatNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter chat name",
                  border: InputBorder.none,
                ),
                onSubmitted: (newChatName) {
                  // Save the new chat name when the user presses "Enter"
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
                  // Enable editing mode when the user taps on the chat name
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
              offset: Offset(0, 5),
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
                              color: Theme.of(context).primaryColor),
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
                          color: Theme.of(context)
                              .primaryColor, // Change this to your desired text color
                        ),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .primaryColor, // Change this to your desired text color
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send,
                          color: Theme.of(context).primaryColor),
                      onPressed: () {
                        // Call the provider's sendMessage method
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
}
