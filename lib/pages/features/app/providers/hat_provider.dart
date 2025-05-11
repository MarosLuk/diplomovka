import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:diplomovka/pages/features/app/providers/invitation_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/components/presentation/pages/hat/hatSpec.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:intl/intl.dart';

class ProblemModel {
  String problemId;
  String problemName;
  List<ContainerModel> containers;
  List<String> collaborators;

  ProblemModel(
      {required this.problemId,
      required this.problemName,
      required this.containers,
      required this.collaborators});
}

class ContainerModel {
  String containerId;
  String containerName;
  List<Map<String, dynamic>> messages;
  String generatedBy;

  ContainerModel({
    required this.containerId,
    required this.containerName,
    required this.messages,
    required this.generatedBy,
  });

  factory ContainerModel.fromFirestore(Map<String, dynamic> data) {
    return ContainerModel(
      containerId: data['containerId'] ?? '',
      containerName: data['containerName'] ?? 'Unnamed Container',
      messages: List<Map<String, dynamic>>.from(data['messages'] ?? []),
      generatedBy: data['generatedBy'] ?? 'Unknown',
    );
  }

  // ✅ Convert the model to a Firestore-compatible format
  Map<String, dynamic> toFirestore() {
    return {
      'containerId': containerId,
      'containerName': containerName,
      'messages': messages,
      'generatedBy': generatedBy,
    };
  }
}

class ProblemNotifier extends StateNotifier<List<ProblemModel>> {
  ProblemNotifier() : super([]) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void removeProblem(String problemId) {
    state = state.where((problem) => problem.problemId != problemId).toList();
  }
/*
  Future<void> uploadSpecificationsWithVotesToFirestore() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final sectionsRef =
          firestore.collection('problemSpecifications').doc('sections');
      final optionContentRef =
          firestore.collection('problemSpecifications').doc('optionContent');

      await sectionsRef.set({'sections': sectionsDatas});

      final transformedOptionContent = optionsContent.map((key, value) {
        final updatedOptions = value.map((Map<String, dynamic> option) {
          return {
            'option': option['option'],
            'upvotes': option['upvotes'] as int,
            'downvotes': option['downvotes'] as int,
            'domainType': option['domainType'],
          };
        }).toList();

        return MapEntry(key, updatedOptions);
      });

      await optionContentRef.set({'optionContent': transformedOptionContent});

      print("Specifications with votes uploaded successfully to Firestore!");
    } catch (e) {
      print("Error uploading specifications: $e");
    }
  }

 */

  Future<void> mergeContainers(
    String problemId,
    ContainerModel targetContainer,
    ContainerModel draggedContainer,
  ) async {
    final problemDocRef = _firestore.collection('problems').doc(problemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(problemDocRef);
      if (!snapshot.exists) {
        throw Exception("Problem does not exist");
      }

      List<dynamic> containers = snapshot.get('containers');
      final targetIndex = containers
          .indexWhere((c) => c['containerId'] == targetContainer.containerId);
      final draggedIndex = containers
          .indexWhere((c) => c['containerId'] == draggedContainer.containerId);

      if (targetIndex == -1 || draggedIndex == -1) {
        throw Exception("Containers not found in the problem data");
      }

      String newGeneratedBy = "User";

      containers[targetIndex]['containerName'] =
          "${targetContainer.containerName} + ${draggedContainer.containerName}";
      containers[targetIndex]['generatedBy'] = newGeneratedBy;

      containers.removeAt(draggedIndex);

      transaction.update(problemDocRef, {
        'containers': containers,
      });
    });

    state = state.map((problem) {
      if (problem.problemId == problemId) {
        final updatedContainers = problem.containers
            .where((c) => c.containerId != draggedContainer.containerId)
            .map((c) {
          if (c.containerId == targetContainer.containerId) {
            return ContainerModel(
              containerId: c.containerId,
              containerName:
                  "${targetContainer.containerName} + ${draggedContainer.containerName}",
              generatedBy: "User",
              messages: c.messages,
            );
          }
          return c;
        }).toList();

        return ProblemModel(
          problemId: problem.problemId,
          problemName: problem.problemName,
          containers: updatedContainers,
          collaborators: problem.collaborators,
        );
      }
      return problem;
    }).toList();
  }

  Future<Map<String, dynamic>> fetchProblemSpecifications() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final sectionsSnapshot = await firestore
          .collection('problemSpecifications')
          .doc('sections')
          .get();
      final sections = sectionsSnapshot.data()?['sections'] as List<dynamic>;

      final optionContentSnapshot = await firestore
          .collection('problemSpecifications')
          .doc('optionContent')
          .get();
      final optionContent =
          optionContentSnapshot.data() as Map<String, dynamic>;

      return {
        'sectionsData': sections,
        'optionContent': optionContent,
      };
    } catch (e) {
      print("Error fetching problem specifications: $e");
      return {};
    }
  }

  Future<void> sendInvite(
      String problemId, String email, String problemName) async {
    try {
      final QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user found with email $email");
        throw Exception("No user found with this email.");
      }

      final validProblemName =
          problemName.isNotEmpty ? problemName : "Unnamed Problem";

      await _firestore.collection('invites').add({
        'problemId': problemId,
        'invitedEmail': email,
        'invitedBy': FirebaseAuth.instance.currentUser!.email,
        'problemName': validProblemName,
      });

      showToast(
        message: "Invite sent to $email",
        isError: false,
      );
    } catch (e) {
      showToast(
        message: "Error sending invite: $e",
        isError: true,
      );
      throw e;
    }
  }

  Future<void> fetchProblems(String userId, String userEmail) async {
    try {
      final userProblemsSnapshot = await _firestore
          .collection('problems')
          .where('userId', isEqualTo: userId)
          .get();

      final participantProblemsSnapshot = await _firestore
          .collection('problems')
          .where('collaborators', arrayContains: userEmail)
          .get();

      final combinedDocs = [
        ...userProblemsSnapshot.docs,
        ...participantProblemsSnapshot.docs
      ];

      final problems = combinedDocs.map((doc) {
        final data = doc.data();

        final problemName = data['problemName'] ?? 'Unknown Problem';
        final containersData = (data['containers'] as List<dynamic>?) ?? [];

        final containers = containersData.map((containerData) {
          return ContainerModel(
            containerId: containerData['containerId'] ?? '',
            containerName:
                containerData['containerName'] ?? 'Unnamed Container',
            messages: List<Map<String, dynamic>>.from(
                containerData['messages'] ?? []),
            generatedBy: containerData['generatedBy'] ?? 'Unknown',
          );
        }).toList();

        final collaborators = List<String>.from(data['collaborators'] ?? []);

        return ProblemModel(
          problemId: doc.id,
          problemName: problemName,
          containers: containers,
          collaborators: collaborators,
        );
      }).toList();

      state = problems;
    } catch (e) {
      print("Error fetching problems: $e");
    }
  }

  Future<String> createNewProblem(
      String problemName, String problemDescription, String userId) async {
    final now = DateTime.now();

    final creationDateTime = DateFormat('dd.MM.yyyy-HH:mm').format(now);

    final newProblem = {
      'problemName': problemName,
      'problemDescription': problemDescription,
      'creationDateTime': creationDateTime,
      'userId': userId,
      'containers': [],
      'collaborators': [],
      'isVerifiedTerms': false,
      'isSpilledHat': false,
      'isSolutionDomain': false,
      'sliderValue': 5.0
    };

    final problemRef = await _firestore.collection('problems').add(newProblem);

    final newProblemModel = ProblemModel(
      problemId: problemRef.id,
      problemName: problemName,
      containers: [],
      collaborators: [],
    );

    state = [...state, newProblemModel];
    return problemRef.id;
  }

  Future<Map<String, String>?> promptForProblemDetails(
      BuildContext context) async {
    TextEditingController problemNameController = TextEditingController();
    TextEditingController problemDescriptionController =
        TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppStyles.background(),
          title: Text(
            'Set up a new Hat',
            style: TextStyle(color: AppStyles.onBackground()),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: problemNameController,
                decoration: const InputDecoration(
                  hintText: "Name",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: TextStyle(color: AppStyles.onBackground()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: problemDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Context description",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: TextStyle(color: AppStyles.onBackground()),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Create'),
              onPressed: () {
                Navigator.of(context).pop({
                  'name': problemNameController.text,
                  'description': problemDescriptionController.text,
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> promptForInviteEmail(
      BuildContext context, String problemId, String problemName) async {
    TextEditingController inviteEmailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppStyles.background(),
          title: Text('Invite User by Email'),
          content: TextField(
            controller: inviteEmailController,
            decoration: InputDecoration(
                hintText: "User email",
                hintStyle: TextStyle(color: AppStyles.onBackground())),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel',
                  style: TextStyle(color: AppStyles.onBackground())),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await sendInvite(
                      problemId, inviteEmailController.text, problemName);
                  Navigator.of(context).pop();
                } catch (e) {
                  print("Error inviting user: $e");
                }
              },
              child: Text('Send Invite',
                  style: TextStyle(color: AppStyles.onBackground())),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteContainer(String problemId, String containerId) async {
    final problemDocRef = _firestore.collection('problems').doc(problemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(problemDocRef);
      if (!snapshot.exists) {
        throw Exception("Problem does not exist");
      }

      List<dynamic> containers = snapshot.get('containers') ?? [];

      // Remove container by ID
      containers.removeWhere((c) => c['containerId'] == containerId);

      // Update Firestore with the modified containers list
      transaction.update(problemDocRef, {'containers': containers});
    });
  }

  Future<void> addContainersToProblem(String problemId,
      Map<String, List<String>> wordsBySection, int generationType) async {
    final problemDocRef = _firestore.collection('problems').doc(problemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(problemDocRef);
      if (!snapshot.exists) {
        throw Exception("Problem does not exist");
      }

      List<dynamic> containers = snapshot.get('containers') ?? [];

      String getGenerationLabel(int type) {
        switch (type) {
          case 0:
            return "AI";
          case 1:
            return "Manual";
          case 2:
            return "User";
          default:
            return "Unknown";
        }
      }

      wordsBySection.forEach((section, words) {
        for (String word in words) {
          String containerId = _firestore.collection('problems').doc().id;
          final newContainer = {
            'containerId': containerId,
            'containerName': "$section: $word",
            'messages': [],
            'generatedBy': getGenerationLabel(generationType),
          };

          containers.add(newContainer);
        }
      });

      transaction.update(problemDocRef, {'containers': containers});
    });
  }

  Future<void> addContainersToProblemCreativity(
      String problemId, List<String> generatedWords, int generationType) async {
    final problemDocRef = _firestore.collection('problems').doc(problemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(problemDocRef);
      if (!snapshot.exists) {
        throw Exception("Problem does not exist");
      }

      List<dynamic> containers = snapshot.get('containers') ?? [];

      if (generatedWords.isEmpty) {
        print("No words to add as containers!");
        return;
      }

      String getGenerationLabel(int type) {
        switch (type) {
          case 0:
            return "AI";
          case 1:
            return "Manual";
          case 2:
            return "User";
          default:
            return "Unknown";
        }
      }

      String generatedBy = getGenerationLabel(generationType);

      for (String word in generatedWords) {
        String containerId = _firestore.collection('problems').doc().id;
        final newContainer = {
          'containerId': containerId,
          'containerName': word.trim(),
          'messages': [],
          'generatedBy': generatedBy,
        };

        print("✅ Adding container: $newContainer");
        containers.add(newContainer);
      }

      transaction.update(problemDocRef, {'containers': containers});
    });

    print("Firestore transaction completed! Containers added successfully.");
  }

  void clearState() {
    state = [];
  }
}

final problemProvider =
    StateNotifierProvider<ProblemNotifier, List<ProblemModel>>(
  (ref) => ProblemNotifier(),
);
