import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalContainers = 0;
  int userGenerated = 0;
  int manualGenerated = 0;
  int aiGenerated = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContainerStatistics();
  }

  Future<void> _fetchContainerStatistics() async {
    try {
      QuerySnapshot problemsSnapshot =
          await _firestore.collection('problems').get();

      List<Map<String, dynamic>> allContainers = [];

      for (var problem in problemsSnapshot.docs) {
        Map<String, dynamic> problemData =
            problem.data() as Map<String, dynamic>;

        if (problemData['containers'] != null) {
          List<Map<String, dynamic>> containers =
              List<Map<String, dynamic>>.from(problemData['containers']);
          allContainers.addAll(containers);
        }
      }

      // Reset counts
      totalContainers = allContainers.length;
      userGenerated = 0;
      manualGenerated = 0;
      aiGenerated = 0;

      for (var container in allContainers) {
        String generatedBy = container['generatedBy'] ?? 'Unknown';

        if (generatedBy == "User") {
          userGenerated++;
        } else if (generatedBy == "Manual") {
          manualGenerated++;
        } else if (generatedBy == "AI") {
          aiGenerated++;
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching statistics: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String _calculatePercentage(int count) {
    if (totalContainers == 0) return "0%";
    return ((count / totalContainers) * 100).toStringAsFixed(2) + "%";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        backgroundColor: AppStyles.backgroundLight(),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Containers: $totalContainers",
                    style: AppStyles.titleMedium(
                        color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem("User Generated", userGenerated),
                  _buildStatItem("Manual Generated", manualGenerated),
                  _buildStatItem("AI Generated", aiGenerated),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String title, int count) {
    return Card(
      color: AppStyles.backgroundLight(),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: AppStyles.labelSmall(color: Theme.of(context).primaryColor),
        ),
        subtitle: Text(
          "Count: $count | Percentage: ${_calculatePercentage(count)}",
          style: AppStyles.titleSmall(color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}
