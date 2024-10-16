import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/pages/features/app/providers/user_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/chat.dart';
import 'package:diplomovka/pages/features/app/providers/chat_provider.dart';
import 'package:diplomovka/pages/features/app/providers/invitation_provider.dart';
import 'dart:async';
import 'package:diplomovka/pages/features/app/providers/problem_provider.dart';

class ProblemPage extends ConsumerStatefulWidget {
  final String problemId;

  const ProblemPage({super.key, required this.problemId});

  @override
  _ProblemPageState createState() => _ProblemPageState();
}

class _ProblemPageState extends ConsumerState<ProblemPage> {
  TextEditingController _containerNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final problem = ref.watch(problemProvider).firstWhere(
          (p) => p.problemId == widget.problemId,
          orElse: () => ProblemModel(
              problemId: widget.problemId,
              problemName: 'Unknown',
              containers: []),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(problem.problemName),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              // Call the promptForInviteEmail for inviting users to the problem
              ref.read(problemProvider.notifier).promptForInviteEmail(
                    context,
                    widget.problemId,
                    problem.problemName,
                  );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: problem.containers.length,
              itemBuilder: (context, index) {
                final container = problem.containers[index];
                return ListTile(
                  title: Text(container.containerName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatPage(chatId: container.containerId),
                      ),
                    );
                  },
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
                    controller: _containerNameController,
                    decoration: InputDecoration(hintText: 'Container name'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    // Add the container to the problem and trigger a UI rebuild
                    ref.read(problemProvider.notifier).addContainerToProblem(
                          widget.problemId,
                          _containerNameController.text,
                        );
                    _containerNameController.clear();
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
