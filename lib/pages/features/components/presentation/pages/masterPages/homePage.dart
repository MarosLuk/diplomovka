import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/pages/features/components/presentation/pages/masterPages/profile_page.dart';
import 'package:diplomovka/pages/features/app/providers/user_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/components/presentation/pages/chatting/chat.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/pages/features/app/providers/invitation_provider.dart';
import 'dart:async';
import 'package:diplomovka/pages/features/app/providers/hat_provider.dart';
import 'package:diplomovka/pages/features/components/presentation/problem/problemPage.dart';
import 'package:diplomovka/pages/features/app/providers/hat_provider.dart';
import 'package:diplomovka/pages/features/components/presentation/pages/gpt/GPT_Page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          backgroundColor: AppStyles.Primary50(),
          title: Text('Invitation'),
          content: Text(
              'You have been invited to the problem "$problemName". Do you accept the invitation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Decline',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.greenAccent),
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
    /*
    ref
        .read(problemProvider.notifier)
        .uploadSpecificationsWithVotesToFirestore();


     */
    if (user != null) {
      ref.read(problemProvider.notifier).fetchProblems(user!.uid, user!.email!);

      ref.read(inviteProvider.notifier).fetchInvites(user!.email!);

      _timer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (user != null) {
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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(usernameProvider);
    final problems = ref.watch(problemProvider);
    final invites = ref.watch(inviteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "SoftHat",
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
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromRGBO(26, 48, 121, 1.0),
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
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Profile',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.primary),
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
            /*
            ListTile(
              leading: Icon(Icons.person,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'GPT',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () async {
                final updatedUsername = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GPTPage(),
                  ),
                );

                if (updatedUsername != null && updatedUsername is String) {
                  ref
                      .read(usernameProvider.notifier)
                      .updateUsername(updatedUsername);
                }
              },
            ),

             */
            ExpansionTile(
              leading: Icon(
                Icons.assignment,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'My Hats',
                style: AppStyles.labelMedium(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              iconColor: Theme.of(context).colorScheme.primary,
              collapsedIconColor: Theme.of(context).colorScheme.primary,
              children: problems.map((problem) {
                return ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      children: [
                        Text(
                          problem.problemName,
                          style: AppStyles.labelLarge(
                              color: Theme.of(context).colorScheme.primary),
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
                  color: Theme.of(context).colorScheme.primary),
              title: Text('Invites',
                  style: AppStyles.labelMedium(
                      color: Theme.of(context).colorScheme.primary)),
              iconColor: Theme.of(context).colorScheme.primary,
              collapsedIconColor: Theme.of(context).colorScheme.primary,
              children: invites.map((invite) {
                return ListTile(
                  title: Text(
                    invite['problemName'] ?? 'Unnamed Problem',
                    style: AppStyles.labelLarge(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  subtitle: Text(
                    "invited by ${invite['invitedBy'] ?? 'Unknown'}",
                    style: AppStyles.labelSmall(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  onTap: () async {
                    bool? accepted =
                        await showInviteDialog(context, invite['problemName']);

                    if (accepted == true) {
                      await ref.read(inviteProvider.notifier).acceptInvite(
                          invite['inviteId'],
                          invite['problemId'],
                          user!.email!);
                      showToast(
                          message: "Invitation accepted.", isError: false);

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
                      await ref
                          .read(inviteProvider.notifier)
                          .deleteInvite(invite['inviteId']);
                      showToast(
                          message: "Invitation declined.", isError: false);
                    }
                  },
                );
              }).toList(),
            ),
            /*ListTile(
              leading: Icon(Icons.settings,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Settings',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () {},
            ),*/
            ListTile(
              leading: Icon(Icons.exit_to_app,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Sign Out',
                style: AppStyles.labelMedium(
                    color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () async {
                ref.read(problemProvider.notifier).clearState();
                ref.read(inviteProvider.notifier).clearState();
                ref.read(usernameProvider.notifier).clearState();

                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('rememberMe', 0);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (Route<dynamic> route) => false,
                );
                showToast(message: "Successfully signed out", isError: false);
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
              colors: [AppStyles.backgroundLight(), AppStyles.background()],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
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
              GestureDetector(
                onTap: () async {
                  final problemDetails = await ref
                      .read(problemProvider.notifier)
                      .promptForProblemDetails(context);

                  if (problemDetails != null &&
                      problemDetails['name']!.isNotEmpty &&
                      problemDetails['description']!.isNotEmpty &&
                      user != null) {
                    String problemId = await ref
                        .read(problemProvider.notifier)
                        .createNewProblem(problemDetails['name']!,
                            problemDetails['description']!, user!.uid);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProblemPage(problemId: problemId),
                      ),
                    );
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create New Hat",
                              style: AppStyles.headLineSmall(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
