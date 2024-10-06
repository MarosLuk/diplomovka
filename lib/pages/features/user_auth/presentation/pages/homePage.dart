import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/profile_page.dart';
import 'package:diplomovka/pages/features/app/providers/user_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/chat.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      // Fetch the chats for the specific user
      ref.read(chatProvider.notifier).fetchChats(user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(usernameProvider);
    final chats = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, $username",
          style: AppStyles.headLineMedium(
            color: Theme.of(context).primaryColor,
          ),
        ),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () async {
              String? chatName = await _promptForChatName(context);
              if (chatName != null && chatName.isNotEmpty && user != null) {
                // Create new chat and pass the userId
                String chatId = await ref
                    .read(chatProvider.notifier)
                    .createNewChat(chatName, user!.uid);

                // Navigate to the newly created chat page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(chatId: chatId),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: Text(
                'Menu',
                style: AppStyles.headLineLarge(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(
                'Profile',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.secondary),
              ),
              onTap: () async {
                final updatedUsername = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );

                if (updatedUsername != null && updatedUsername is String) {
                  ref
                      .read(usernameProvider.notifier)
                      .updateUsername(updatedUsername);
                }
              },
            ),
            ExpansionTile(
              leading: Icon(
                Icons.chat,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                'Chats',
                style: AppStyles.labelMedium(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              // Set the icon color when the tile is expanded
              iconColor: Theme.of(context)
                  .colorScheme
                  .secondary, // Color when expanded
              collapsedIconColor: Theme.of(context)
                  .colorScheme
                  .secondary, // Color when collapsed
              children: chats.map((chat) {
                return ListTile(
                  title: Text(chat.chatName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(chatId: chat.chatId),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            ListTile(
              leading: Icon(Icons.settings,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(
                'Settings',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.secondary),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(
                'Sign Out',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.secondary),
              ),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, "/login");
                showToast(message: "Successfully signed out");
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to Home",
                style: AppStyles.headLineLarge(
                    color: Theme.of(context).primaryColor),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _promptForChatName(BuildContext context) async {
    TextEditingController chatNameController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter chat name'),
          content: TextField(
            controller: chatNameController,
            decoration: const InputDecoration(hintText: "Chat name"),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Create', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(chatNameController.text);
              },
            ),
          ],
        );
      },
    );
  }
}
