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
import 'package:diplomovka/pages/features/app/providers/problem_provider.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/problemPage.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Timer? _timer;

  Future<bool?> showInviteDialog(BuildContext context, String problemName) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invitation'),
          content: Text(
              'You have been invited to the problem "$problemName". Do you accept the invitation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Decline
              child: Text(
                'Decline',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Accept
              child: Text(
                'Accept',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (user != null) {
      print("User: $user");

      // Add these prints for debugging
      print("About to call fetchProblems");
      ref.read(problemProvider.notifier).fetchProblems(user!.uid, user!.email!);

      print("About to call fetchInvites");
      ref.read(inviteProvider.notifier).fetchInvites(user!.email!);

      _timer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (user != null) {
          print("Timer triggered: Fetching problems and invites");
          ref
              .read(problemProvider.notifier)
              .fetchProblems(user!.uid, user!.email!);
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
    final problems =
        ref.watch(problemProvider); // Watch problems instead of chats
    final invites = ref.watch(inviteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "HELPIE",
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
              Icons.add_circle_outline,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () async {
              String? problemName = await ref
                  .read(problemProvider.notifier)
                  .promptForProblemName(context);
              if (problemName != null &&
                  problemName.isNotEmpty &&
                  user != null) {
                String problemId = await ref
                    .read(problemProvider.notifier)
                    .createNewProblem(problemName, user!.uid);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProblemPage(problemId: problemId),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white70,
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
                Icons.assignment,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(
                'Problems',
                style: AppStyles.labelMedium(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              iconColor: Theme.of(context).colorScheme.secondary,
              collapsedIconColor: Theme.of(context).colorScheme.secondary,
              children: problems.map((problem) {
                return ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      children: [
                        Text(
                          problem.problemName,
                          style: AppStyles.labelLarge(color: Colors.black45),
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProblemPage(problemId: problem.problemId),
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
                    invite['problemName'] ??
                        'Unnamed Problem', // Handle null problemName
                    style: AppStyles.labelLarge(color: Colors.black45),
                  ),
                  subtitle: Text(
                    "(invited by ${invite['invitedBy'] ?? 'Unknown'})", // Handle null invitedBy
                    style: AppStyles.labelSmall(color: Colors.black45),
                  ),
                  onTap: () async {
                    // Display the prompt for accepting or declining the invite
                    bool? accepted =
                        await showInviteDialog(context, invite['problemName']);

                    if (accepted == true) {
                      // If the user accepted the invite, add the problem to their list
                      await ref.read(inviteProvider.notifier).acceptInvite(
                          invite['inviteId'],
                          invite['problemId'],
                          user!.email!);
                      showToast(message: "Invitation accepted.");

                      // After accepting, fetch updated problems and navigate to the problem page
                      await ref
                          .read(problemProvider.notifier)
                          .fetchProblems(user!.uid, user!.email!);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProblemPage(problemId: invite['problemId']),
                        ),
                      );
                    } else if (accepted == false) {
                      // If the user declined the invite, delete the invitation
                      await ref
                          .read(inviteProvider.notifier)
                          .deleteInvite(invite['inviteId']);
                      showToast(message: "Invitation declined.");
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
                ref.read(problemProvider.notifier).clearState();
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
