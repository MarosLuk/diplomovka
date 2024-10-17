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
              containers: [],
              collaborators: []),
        );

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: AppStyles.onBackground(),
        ),
        title: Text(
          problem.problemName,
          style: TextStyle(color: AppStyles.onBackground()),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.person_add,
              color: AppStyles.onBackground(),
            ),
            onPressed: () {
              ref.read(problemProvider.notifier).promptForInviteEmail(
                    context,
                    widget.problemId,
                    problem.problemName,
                  );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: problem.containers.length,
                  itemBuilder: (context, index) {
                    final container = problem.containers[index];
                    return ListTile(
                      title: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 2, color: AppStyles.onBackground()),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            container.containerName,
                            style: TextStyle(color: AppStyles.onBackground()),
                          ),
                        ),
                      ),
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
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _containerNameController,
                        decoration: InputDecoration(
                            hintText: 'New container',
                            hintStyle: TextStyle(
                                color:
                                    AppStyles.onBackground().withOpacity(0.4))),
                        style: TextStyle(
                          color: AppStyles.onBackground(),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color: AppStyles.onBackground(),
                      ),
                      onPressed: () {
                        ref
                            .read(problemProvider.notifier)
                            .addContainerToProblem(
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
        ),
      ),
    );
  }
}
