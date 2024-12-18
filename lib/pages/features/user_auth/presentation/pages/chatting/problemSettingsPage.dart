import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/providers/problem_provider.dart';

class SettingsProblemPage extends ConsumerStatefulWidget {
  final String problemId;

  const SettingsProblemPage({Key? key, required this.problemId})
      : super(key: key);

  @override
  _SettingsProblemPageState createState() => _SettingsProblemPageState();
}

class _SettingsProblemPageState extends ConsumerState<SettingsProblemPage> {
  Future<Map<String, dynamic>> _fetchProblemDetails(String problemId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('problems')
        .doc(problemId)
        .get();

    if (!docSnapshot.exists) {
      throw Exception("Problem not found");
    }

    return docSnapshot.data()!;
  }

  Future<String> _fetchOwnerEmail(String userId) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot.data()?['email'] ?? 'Unknown Email';
      } else {
        return 'Unknown Email';
      }
    } catch (e) {
      print("Error fetching owner's email: $e");
      return 'Unknown Email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Problem Settings',
          style: AppStyles.headLineMedium(color: AppStyles.onBackground()),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProblemDetails(widget.problemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading problem details",
                style: AppStyles.headLineSmall(color: Colors.red),
              ),
            );
          }

          final problemData = snapshot.data!;
          final collaborators =
              List<String>.from(problemData['collaborators'] ?? []);
          final containers =
              List<dynamic>.from(problemData['containers'] ?? []);

          return FutureBuilder<String>(
            future: _fetchOwnerEmail(problemData['userId']),
            builder: (context, emailSnapshot) {
              if (emailSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final ownerEmail = emailSnapshot.data ?? 'Unknown Email';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(problemProvider.notifier)
                                .promptForInviteEmail(
                                  context,
                                  widget.problemId,
                                  problemData['problemName'],
                                );
                          },
                          child: const Text("Add Collaborator"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Problem Details",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Name: ${problemData['problemName']}",
                        style: AppStyles.bodyLarge(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Description: ${problemData['problemDescription'] ?? 'No description'}",
                        style: AppStyles.bodyLarge(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Created At: ${problemData['creationDateTime']}",
                        style: AppStyles.bodyLarge(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Owner: $ownerEmail",
                        style: AppStyles.bodyLarge(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Collaborators:",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      ...collaborators.map((collaborator) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              "- $collaborator",
                              style: AppStyles.bodyLarge(
                                  color: AppStyles.onBackground()),
                            ),
                          )),
                      const SizedBox(height: 12),
                      Text(
                        "Containers:",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      ...containers.map(
                        (container) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            "- ${container['containerName']}",
                            style: AppStyles.bodyLarge(
                                color: AppStyles.onBackground()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
