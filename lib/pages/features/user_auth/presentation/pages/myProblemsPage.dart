import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/app/providers/problem_provider.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/chatting/problemPage.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class MyHatsPage extends ConsumerWidget {
  const MyHatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problems = ref.watch(problemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Problems',
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
            ),
          );
        },
      ),
    );
  }
}
