import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/pages/features/app/providers/user_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String problemId;
  final String chatId;
  final String containerName;

  const ChatPage({
    super.key,
    required this.problemId,
    required this.chatId,
    required this.containerName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _isEditingName = false;
  TextEditingController _chatNameController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";
  bool _shouldScrollToBottom = true;
  bool _showScrollToBottomButton = false;
  Timer? _fetchTimer;

  bool _isMentioning = false;
  List<Map<String, dynamic>> availableContainers = [];

  @override
  void initState() {
    super.initState();

    _startFetchingMessages();
    _fetchContainers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchContainers() async {
    final firestore = FirebaseFirestore.instance;
    final problemRef = firestore.collection('problems').doc(widget.problemId);
    final snapshot = await problemRef.get();

    if (snapshot.exists) {
      final problemData = snapshot.data();
      if (problemData != null && problemData.containsKey('containers')) {
        final containersRaw = problemData['containers'] as List<dynamic>;
        setState(() {
          availableContainers = containersRaw.map((c) {
            return {
              'containerName': c['containerName'],
              'containerId': c['containerId'],
            };
          }).toList();
        });
      }
    }
  }

  void _onMessageChanged(String value) {
    if (value.contains('@') && !_isMentioning) {
      setState(() {
        _isMentioning = true;
      });
    } else if (!value.contains('@') && _isMentioning) {
      setState(() {
        _isMentioning = false;
      });
    }
  }

  void _onContainerSelected(String containerName) {
    final text = messageController.text;
    final mentionIndex = text.lastIndexOf('@');
    if (mentionIndex != -1) {
      final newText = text.substring(0, mentionIndex + 1) + containerName + " ";
      messageController.text = newText;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      setState(() {
        _isMentioning = false;
      });
    }
  }

  void _onMentionClicked(String containerName) {
    final selectedContainer = availableContainers.firstWhere(
      (c) => c['containerName'] == containerName,
      orElse: () => {},
    );
    if (selectedContainer != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            problemId: widget.problemId,
            chatId: selectedContainer['containerId'],
            containerName: selectedContainer['containerName'],
          ),
        ),
      );
    }
  }

  void _startFetchingMessages() {
    _fetchTimer = Timer.periodic(Duration(milliseconds: 2500), (timer) async {
      final messages = await ref
          .read(chatProvider.notifier)
          .fetchMessages(widget.problemId, widget.chatId);
    });
  }

  void _onScroll() {
    final distanceFromBottom = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;

    if (distanceFromBottom >= 500) {
      _shouldScrollToBottom = false;
      setState(() {
        _showScrollToBottomButton = true;
      });
    } else if (distanceFromBottom > 0 && distanceFromBottom < 500) {
      _shouldScrollToBottom = false;
      setState(() {
        _showScrollToBottomButton = false;
      });
    } else if (distanceFromBottom == 0) {
      _shouldScrollToBottom = true;
      setState(() {
        _showScrollToBottomButton = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _chatNameController.dispose();
    messageController.dispose();
    _scrollController.dispose();
    _fetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building ChatPage for chatId: ${widget.chatId}");
    final chatModel = ref.watch(chatProvider).firstWhere(
        (chat) => chat.chatId == widget.chatId,
        orElse: () => ChatModel(
            chatId: widget.chatId, chatName: 'Unknown', messages: []));
    print("Messages in chatModel: ${chatModel.messages}");

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
                  widget.containerName,
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
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
                          final senderEmail = message['senderEmail'] ??
                              'Unknown'; // Use email as identity
                          final isCurrentUser = senderEmail == currentUserEmail;

                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  senderEmail,
                                  // Display the email instead of username
                                  style: AppStyles.labelSmall(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (message['message'].startsWith('@')) {
                                      _onMentionClicked(message['message']
                                          .substring(1)
                                          .trim());
                                    }
                                  },
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.6,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? Colors.blue[400]
                                            : Colors.black45,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        message['message'],
                                        style: AppStyles.titleSmall(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isMentioning)
                      Container(
                        height: 200,
                        color: Colors.white,
                        child: ListView.builder(
                          itemCount: availableContainers.length,
                          itemBuilder: (context, index) {
                            final container = availableContainers[index];
                            return ListTile(
                              title: Text(container['containerName']),
                              onTap: () => _onContainerSelected(
                                  container['containerName']),
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
                              onChanged: _onMessageChanged,
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
                              if (messageController.text.isNotEmpty) {
                                ref.read(chatProvider.notifier).sendMessage(
                                      widget.problemId,
                                      widget.chatId,
                                      messageController.text,
                                      currentUserEmail,
                                    );
                                messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showScrollToBottomButton)
              Positioned(
                bottom: 130,
                right: 20,
                child: GestureDetector(
                  onTap: _scrollToBottom,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
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
      ),
    );
  }
}
