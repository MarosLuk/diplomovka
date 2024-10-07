import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/profile_page.dart';
import 'package:diplomovka/pages/features/app/providers/user_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/chat.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/pages/features/app/providers/invitation_provider.dart';
import 'dart:async';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      // Initial fetch

      ref.read(chatProvider.notifier).fetchChats(user!.uid, user!.email!);

      // Fetch invites
      ref.read(inviteProvider.notifier).fetchInvites(user!.email!);

      // Set up periodic fetch every 2 seconds
      _timer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (user != null) {
          ref.read(chatProvider.notifier).fetchChats(user!.uid, user!.email!);
          ref.read(inviteProvider.notifier).fetchInvites(user!.email!);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(usernameProvider);
    final chats = ref.watch(chatProvider);
    final invites = ref.watch(inviteProvider);

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
              String? chatName = await ref
                  .read(inviteProvider.notifier)
                  .promptForChatName(context);
              if (chatName != null && chatName.isNotEmpty && user != null) {
                String chatId = await ref
                    .read(chatProvider.notifier)
                    .createNewChat(chatName, user!.uid);

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
              iconColor: Theme.of(context).colorScheme.secondary,
              collapsedIconColor: Theme.of(context).colorScheme.secondary,
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
            ExpansionTile(
              leading: Icon(Icons.mail,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text('Invites',
                  style: AppStyles.labelMedium(
                      color: Theme.of(context).colorScheme.secondary)),
              iconColor: Theme.of(context).colorScheme.secondary,
              collapsedIconColor: Theme.of(context).colorScheme.secondary,
              children: invites.map((invite) {
                return ListTile(
                  title: Text(
                      "${invite['chatName']} (invited by ${invite['invitedBy']})"),
                  onTap: () async {
                    // Show popup for accepting or declining the invite
                    bool accepted = await ref
                        .read(inviteProvider.notifier)
                        .showInvitePopup(context, invite['chatName']);
                    if (accepted) {
                      // Accept the invite and add user to the chat
                      await ref.read(inviteProvider.notifier).acceptInvite(
                          invite['inviteId'], invite['chatId'], user!.email!);

                      // After accepting, fetch updated list of chats
                      await ref
                          .read(chatProvider.notifier)
                          .fetchChats(user!.uid, user!.email!);

                      // Navigate to the chat page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ChatPage(chatId: invite['chatId'])),
                      );
                    }
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
              onTap: () async {
                ref.read(chatProvider.notifier).clearState();
                ref.read(inviteProvider.notifier).clearState();
                ref.read(usernameProvider.notifier).clearState();

                await FirebaseAuth.instance.signOut();

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
}
