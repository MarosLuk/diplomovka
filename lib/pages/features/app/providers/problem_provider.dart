import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:diplomovka/pages/features/app/providers/invitation_provider.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

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

  ContainerModel({
    required this.containerId,
    required this.containerName,
    required this.messages,
  });
}

class ProblemNotifier extends StateNotifier<List<ProblemModel>> {
  ProblemNotifier() : super([]) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      print("Invite sent to $email");
    } catch (e) {
      print("Error sending invite: $e");
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

  Future<String> createNewProblem(String problemName, String userId) async {
    final newProblem = {
      'problemName': problemName,
      'userId': userId,
      'containers': [],
      'collaborators': [],
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

  Future<String?> promptForProblemName(BuildContext context) async {
    TextEditingController problemNameController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppStyles.background(),
          title: Text(
            'Enter problem name',
            style: TextStyle(color: AppStyles.onBackground()),
          ),
          content: TextField(
            controller: problemNameController,
            decoration: InputDecoration(
              hintText: "Problem name",
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: TextStyle(color: AppStyles.onBackground()),
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
                Navigator.of(context).pop(problemNameController.text);
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

  Future<void> addContainerToProblem(
      String problemId, String containerName) async {
    final newContainer = {
      'containerName': containerName,
      'messages': [],
    };

    final problemDocRef = _firestore.collection('problems').doc(problemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(problemDocRef);
      if (!snapshot.exists) {
        throw Exception("Problem does not exist");
      }

      List<dynamic> containers = snapshot.get('containers') ?? [];
      containers.add(newContainer);

      transaction.update(problemDocRef, {'containers': containers});
    });
  }

  void clearState() {
    state = [];
  }
}

final problemProvider =
    StateNotifierProvider<ProblemNotifier, List<ProblemModel>>(
  (ref) => ProblemNotifier(),
);
