import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/reusableComponents/reusableComponents.dart';
import 'package:diplomovka/pages/features/app/providers/profile_provider.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/problemSettingsPage.dart';
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
import 'package:flutter_slidable/flutter_slidable.dart';

class SelectionNotifier extends StateNotifier<Map<String, dynamic>> {
  SelectionNotifier() : super({"selections": {}, "isLoading": false});

  void toggleSelection(String option) {
    state = {
      ...state,
      "selections": {
        ...state["selections"],
        option: !(state["selections"][option] ?? false),
      },
    };
  }

  void clearSelections() {
    state = {"selections": {}, "isLoading": false};
  }

  bool get isLoading => state["isLoading"];

  Map<String, List<String>> getSelectedOptionsGroupedBySections(
      List<Map<String, dynamic>> sections) {
    final selectedGroupedBySections = <String, List<String>>{};
    final selections = state["selections"];

    for (var section in sections) {
      final sectionTitle = section['title'] as String;
      final sectionOptions = (section['keyFocus'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      final selectedOptionsForSection =
          sectionOptions.where((option) => selections[option] == true).toList();

      if (selectedOptionsForSection.isNotEmpty) {
        selectedGroupedBySections[sectionTitle] = selectedOptionsForSection;
      }
    }

    return selectedGroupedBySections;
  }

  Future<bool> checkIfUsingGPT(String problemId) async {
    final firestore = FirebaseFirestore.instance;
    final problemSnapshot =
        await firestore.collection('problems').doc(problemId).get();

    if (!problemSnapshot.exists) {
      throw Exception("Problem settings not found.");
    }

    final problemData = problemSnapshot.data() as Map<String, dynamic>;
    return problemData['isVerifiedTerms'] ?? false;
  }

  final isOutsideSoftwareProvider = StateProvider<bool>((ref) => false);

  Future<void> saveSelections(
      WidgetRef ref,
      BuildContext context,
      String problemId,
      List<Map<String, dynamic>> sections,
      Map<String, dynamic> rawOptionContent) async {
    try {
      state = {...state, "isLoading": true};
      Navigator.of(context).pop();
      final selectedGrouped = getSelectedOptionsGroupedBySections(sections);
      print("Selected options grouped by sections: $selectedGrouped");

      final unwrappedOptionContent = rawOptionContent['optionContent'];
      if (unwrappedOptionContent is! Map<String, dynamic>) {
        throw Exception("Invalid format for unwrapped optionContent");
      }

      final bool isGPTGenerated = await checkIfUsingGPT(problemId);
      final generatedWords =
          await generateSectionWords(sections, selectedGrouped, problemId);

      int generationType = isGPTGenerated ? 0 : 1;

      await ref
          .read(problemProvider.notifier)
          .addContainersToProblem(problemId, generatedWords, generationType);

      clearSelections();
    } catch (e) {
      showToast(
        message: "Error in saveSelections: $e",
        isError: true,
      );
    } finally {
      state = {...state, "isLoading": false};
    }
  }

  Future<void> saveSelectionsCreativity(
    WidgetRef ref,
    BuildContext context,
    String problemId,
  ) async {
    try {
      state = {...state, "isLoading": true};

      final bool isGPTGenerated = await checkIfUsingGPT(problemId);
      final generatedWords = await generateSectionWordsCreativity(problemId);

      int generationType = isGPTGenerated ? 0 : 1;

      await ref.read(problemProvider.notifier).addContainersToProblemCreativity(
          problemId, generatedWords, generationType);

      clearSelections();
    } catch (e) {
      showToast(
        message: "Error in saveSelections: $e",
        isError: true,
      );
      print("Error in saveSelections: $e");
    } finally {
      state = {...state, "isLoading": false};
    }
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, Map<String, dynamic>>(
  (ref) => SelectionNotifier(),
);

class ProblemPage extends ConsumerStatefulWidget {
  final String problemId;

  const ProblemPage({super.key, required this.problemId});

  @override
  _ProblemPageState createState() => _ProblemPageState();
}

class _ProblemPageState extends ConsumerState<ProblemPage> {
  bool _isOutsideSoftware = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchIsOutsideSoftware() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final problemSnapshot =
          await firestore.collection('problems').doc(widget.problemId).get();

      if (problemSnapshot.exists) {
        final data = problemSnapshot.data();
        if (data != null) {
          setState(() {
            _isOutsideSoftware = data['isOutsideSoftware'] ?? false;
          });
          print("Updated isOutsideSoftware: $_isOutsideSoftware");
        }
      } else {
        print("Problem document does not exist.");
      }
    } catch (e) {
      print("Error fetching isOutsideSoftware: $e");
    }
  }

  void _showAddContainerDialog(BuildContext context, WidgetRef ref) async {
    TextEditingController _containerController = TextEditingController();

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast(message: "User not logged in!", isError: true);
      return;
    }

    final userData = await ref.read(profileProvider.notifier).fetchUserData();
    final String username =
        userData['username'] ?? user.email ?? "Unknown User";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppStyles.Primary50(),
          title: Text("Add Custom Container"),
          content: TextField(
            controller: _containerController,
            decoration: InputDecoration(hintText: "Enter container name"),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Add"),
              onPressed: () async {
                String containerName = _containerController.text.trim();
                if (containerName.isNotEmpty) {
                  await ref
                      .read(problemProvider.notifier)
                      .addContainersToProblem(
                          widget.problemId,
                          {
                            username: [containerName]
                          },
                          2);

                  Navigator.pop(context);
                } else {
                  showToast(
                      message: "Container name cannot be empty!",
                      isError: true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void specificationBottomSheet(BuildContext context, WidgetRef ref) async {
    try {
      final fetchedData =
          await ref.read(problemProvider.notifier).fetchProblemSpecifications();

      if (fetchedData.isEmpty) {
        showToast(
          message: "Failed to load specifications data.",
          isError: true,
        );
        print("Failed to load specifications data.");
        return;
      }

      final sectionsData = (fetchedData['sectionsData'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final optionContent =
          fetchedData['optionContent'] as Map<String, dynamic>;

      // Display the bottom sheet
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
              height: MediaQuery.of(context).size.height * 0.8,
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
                                style: AppStyles.headLineSmall(
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: ref.watch(selectionProvider)["isLoading"]
                              ? null
                              : () => ref
                                  .read(selectionProvider.notifier)
                                  .saveSelections(
                                      ref,
                                      context,
                                      widget.problemId,
                                      sectionsData,
                                      optionContent),
                          child: Container(
                            width: 100,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: ref.watch(selectionProvider)["isLoading"]
                                  ? CircularProgressIndicator(
                                      color: Colors.black)
                                  : Text(
                                      "Confirm",
                                      style: AppStyles.headLineSmall(
                                          color: Colors.black),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (var section in sectionsData) ...[
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
                              final selections = Map<String, bool>.from(
                                  ref.watch(selectionProvider)["selections"]);
                              final isSelected = selections[focus] ?? false;

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
    } catch (e) {
      print("Error parsing data : $e");
      showToast(
        message: "Error parsing data : $e",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(selectionProvider)["isLoading"] ?? false;
    final problem = ref.watch(problemProvider).firstWhere(
          (p) => p.problemId == widget.problemId,
          orElse: () => ProblemModel(
            problemId: widget.problemId,
            problemName: 'Unknown',
            containers: [],
            collaborators: [],
          ),
        );

    return Stack(
      children: [
        Scaffold(
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
                  Icons.settings,
                  color: AppStyles.onBackground(),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsProblemPage(problemId: widget.problemId),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.add, color: AppStyles.onBackground()),
                onPressed: () => _showAddContainerDialog(context, ref),
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

                        return Slidable(
                          key: Key(container.containerId),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) async {
                                  await ref
                                      .read(problemProvider.notifier)
                                      .deleteContainer(widget.problemId,
                                          container.containerId);
                                  showToast(
                                      message: "Container deleted",
                                      isError: false);
                                },
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                                borderRadius: BorderRadius.circular(100),
                                padding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                              ),
                            ],
                          ),
                          child: LongPressDraggable<ContainerModel>(
                            data: container,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  container.containerName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.5,
                              child: buildContainerTile(context, container),
                            ),
                            child: DragTarget<ContainerModel>(
                              builder: (BuildContext context,
                                  List<ContainerModel?> candidateData,
                                  List<dynamic> rejectedData) {
                                final isDraggingOver = candidateData.isNotEmpty;
                                return Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 2,
                                      color: isDraggingOver
                                          ? Colors.green
                                          : AppStyles.onBackground(),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: buildContainerTile(context, container),
                                );
                              },
                              onWillAccept: (draggedContainer) {
                                if (draggedContainer == null) return false;
                                return draggedContainer.containerId !=
                                    container.containerId;
                              },
                              onAccept: (draggedContainer) async {
                                await ref
                                    .read(problemProvider.notifier)
                                    .mergeContainers(widget.problemId,
                                        container, draggedContainer);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _fetchIsOutsideSoftware();

                      if (_isOutsideSoftware) {
                        ref
                            .read(selectionProvider.notifier)
                            .saveSelectionsCreativity(
                              ref,
                              context,
                              widget.problemId,
                            );
                      } else {
                        specificationBottomSheet(context, ref);
                      }
                    },
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
                                SizedBox(width: 4),
                                Text(
                                  "Pick from Hat",
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
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openProblemChat(context, problem),
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.chat, color: Colors.white),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  void _openProblemChat(BuildContext context, ProblemModel problem) async {
    final firestore = FirebaseFirestore.instance;
    final problemRef = firestore.collection('problems').doc(widget.problemId);

    await problemRef.set({
      'messagesProblem': FieldValue.arrayUnion([]),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          problemId: widget.problemId,
          chatId: "messagesProblem",
          containerName: problem.problemName,
        ),
      ),
    );
  }

  Widget buildContainerTile(BuildContext context, ContainerModel container) {
    bool isManualGenerated = container.generatedBy == "User";

    return ListTile(
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          container.containerName,
          style: TextStyle(color: AppStyles.onBackground()),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isManualGenerated)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                regenerateContainer(
                  context,
                  widget.problemId,
                  container.containerId,
                  container.containerName,
                  ref,
                );
              },
            ),
          if (!isManualGenerated)
            IconButton(
              icon: Icon(Icons.info_outline, color: AppStyles.Primary50()),
              onPressed: () {
                final parts = container.containerName.split(": ");
                if (parts.length == 2) {
                  final section = parts[0].trim();
                  final option = parts[1].trim();

                  final subsections = sectionToSubsections[section];
                  if (subsections != null) {
                    showVoteDialog(context, subsections, option, ref);
                  } else {
                    print("Section not found in mapping: $section");
                    showToast(
                      message: "Section not found in mapping: $section",
                      isError: true,
                    );
                  }
                } else {
                  print(
                      "Invalid container name format: ${container.containerName}");
                  showToast(
                    message:
                        "Invalid container name format: ${container.containerName}",
                    isError: true,
                  );
                }
              },
            ),
        ],
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
  }
}
