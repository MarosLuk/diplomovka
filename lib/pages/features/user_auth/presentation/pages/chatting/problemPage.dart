import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/reusableComponents/reusableComponents.dart';
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
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/problemSpec.dart';

class SelectionNotifier extends StateNotifier<Map<String, bool>> {
  SelectionNotifier() : super({});

  void toggleSelection(String option) {
    state = {
      ...state,
      option: !(state[option] ?? false),
    };
  }

  void clearSelections() {
    state = {};
  }

  Map<String, List<String>> getSelectedOptionsGroupedBySections(
      List<Map<String, dynamic>> sections) {
    final selectedGroupedBySections = <String, List<String>>{};

    for (var section in sections) {
      final sectionTitle = section['title'] as String;
      final sectionOptions = section['keyFocus'] as List<String>;

      final selectedOptionsForSection =
          sectionOptions.where((option) => state[option] == true).toList();

      if (selectedOptionsForSection.isNotEmpty) {
        selectedGroupedBySections[sectionTitle] = selectedOptionsForSection;
      }
    }

    return selectedGroupedBySections;
  }

  void saveSelections(WidgetRef ref, BuildContext context, String problemId,
      List<Map<String, dynamic>> sections) async {
    final selectedGrouped = getSelectedOptionsGroupedBySections(sections);

    print("Selected options grouped by sections: $selectedGrouped");

    final generatedWords = generateSectionWords(sections, selectedGrouped);
    print("Generated words for each section: $generatedWords");

    await ref
        .read(problemProvider.notifier)
        .addContainersToProblem(problemId, generatedWords);

    Navigator.of(context).pop();
    clearSelections();
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, Map<String, bool>>(
  (ref) => SelectionNotifier(),
);

class ProblemPage extends ConsumerStatefulWidget {
  final String problemId;

  const ProblemPage({super.key, required this.problemId});

  @override
  _ProblemPageState createState() => _ProblemPageState();
}

class _ProblemPageState extends ConsumerState<ProblemPage> {
  TextEditingController _containerNameController = TextEditingController();

  void specificationBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppStyles.Primary50(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height *
                0.8, // 80% of screen height
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Reusablecomponents.bottomSheetTopButton(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: ref
                            .read(selectionProvider.notifier)
                            .clearSelections,
                        child: Container(
                          width: 100,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "Clear",
                              style:
                                  AppStyles.headLineSmall(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(selectionProvider.notifier)
                            .saveSelections(
                                ref, context, widget.problemId, sectionsData),
                        child: Container(
                          width: 100,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              "Save",
                              style:
                                  AppStyles.headLineSmall(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var section in sectionsData) ...[
                    // Section title
                    Text(
                      section['title'],
                      style: AppStyles.titleMedium(color: Colors.white),
                    ),
                    const SizedBox(height: 8),

                    for (var focus in section['keyFocus'])
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(selectionProvider.notifier)
                              .toggleSelection(focus);
                        },
                        child: Consumer(
                          builder: (context, ref, _) {
                            final isSelected =
                                ref.watch(selectionProvider)[focus] ?? false;
                            return Container(
                              height: 50,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green[200]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  focus,
                                  style: AppStyles.labelMedium(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    Divider(
                      color: AppStyles.Primary30(),
                      thickness: 1,
                      height: 32,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
                            builder: (context) => ChatPage(
                              problemId: widget.problemId,
                              chatId: container.containerId,
                              containerName: container.containerName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              GestureDetector(
                onTap: () => specificationBottomSheet(context, ref),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppStyles.Primary50(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add,
                              color: AppStyles.onBackground(),
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              "Add specification",
                              style:
                                  AppStyles.headLineSmall(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
