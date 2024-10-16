import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:diplomovka/pages/features/app/providers/invitation_provider.dart';

class ProblemModel {
  String problemId;
  String problemName;
  List<ContainerModel> containers;

  ProblemModel({
    required this.problemId,
    required this.problemName,
    required this.containers,
  });
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
      // Check if the user with the provided email exists
      final QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user found with email $email");
        throw Exception("No user found with this email.");
      }

      // Ensure that problemName is not null
      final validProblemName =
          problemName.isNotEmpty ? problemName : "Unnamed Problem";

      // Send the invite with the current problem name if the email exists
      await _firestore.collection('invites').add({
        'problemId': problemId,
        'invitedEmail': email,
        'invitedBy': FirebaseAuth.instance.currentUser!.email,
        'problemName': validProblemName, // Ensure a valid name is stored
      });

      print("Invite sent to $email");
    } catch (e) {
      print("Error sending invite: $e");
      throw e;
    }
  }

  Future<void> fetchProblems(String userId, String userEmail) async {
    try {
      print("Fetching problems for userId: $userId, userEmail: $userEmail");

      final userProblemsSnapshot = await _firestore
          .collection('problems')
          .where('userId', isEqualTo: userId)
          .get();

      final participantProblemsSnapshot = await _firestore
          .collection('problems')
          .where('participants', arrayContains: userEmail)
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

        return ProblemModel(
          problemId: doc.id,
          problemName: problemName,
          containers: containers,
        );
      }).toList();

      print("Problems fetched: ${problems.length}");
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
    };

    final problemRef = await _firestore.collection('problems').add(newProblem);
    final newProblemModel = ProblemModel(
      problemId: problemRef.id,
      problemName: problemName,
      containers: [],
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
          backgroundColor: Colors.deepPurple[600],
          title: Text(
            'Enter problem name',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: problemNameController,
            decoration: InputDecoration(
              hintText: "Problem name",
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: TextStyle(color: Colors.white),
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
          title: Text('Invite User by Email'),
          content: TextField(
            controller: inviteEmailController,
            decoration: InputDecoration(hintText: "User email"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Call sendInvite method
                  await sendInvite(
                      problemId, inviteEmailController.text, problemName);
                  Navigator.of(context).pop();
                } catch (e) {
                  print("Error inviting user: $e");
                }
              },
              child: Text('Send Invite', style: TextStyle(color: Colors.green)),
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
