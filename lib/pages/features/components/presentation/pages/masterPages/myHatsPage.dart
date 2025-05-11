import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/pages/features/app/providers/hat_provider.dart';
import 'package:diplomovka/pages/features/components/presentation/pages/hat/mainHatPage.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

import '../../../../app/global/toast.dart';

class MyHatsPage extends ConsumerWidget {
  const MyHatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problems = ref.watch(problemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Hats',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: problems.length,
        itemBuilder: (context, index) {
          final problem = problems[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            color: AppStyles.backgroundLight(),
            child: ListTile(
              title: Text(
                problem.problemName,
                style: AppStyles.labelLarge(
                  color: AppStyles.onBackground(),
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
              onLongPress: () =>
                  _showDeleteDialog(context, problem.problemId, ref),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, String problemId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.Primary50(),
        title: const Text("Delete Problem"),
        content: const Text(
            "Are you sure you want to delete this problem? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProblem(problemId, ref);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProblem(String problemId, WidgetRef ref) async {
    try {
      await FirebaseFirestore.instance
          .collection('problems')
          .doc(problemId)
          .delete();

      ref.read(problemProvider.notifier).removeProblem(problemId);

      debugPrint("Problem deleted successfully!");
      showToast(message: "Problem deleted successfully!", isError: false);
    } catch (e) {
      debugPrint("Error deleting problem: $e");
      showToast(message: "Error deleting problem: $e", isError: true);
    }
  }
}
