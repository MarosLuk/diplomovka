import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class ProblemContainersPage extends ConsumerStatefulWidget {
  final String problemId;
  const ProblemContainersPage({Key? key, required this.problemId})
      : super(key: key);

  @override
  _ProblemContainersPageState createState() => _ProblemContainersPageState();
}

class _ProblemContainersPageState extends ConsumerState<ProblemContainersPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _containers = [];

  @override
  void initState() {
    super.initState();
    _fetchContainers();
  }

  Future<void> _fetchContainers() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot problemSnapshot = await FirebaseFirestore.instance
          .collection('problems')
          .doc(widget.problemId)
          .get();

      if (problemSnapshot.exists) {
        Map<String, dynamic> data =
            problemSnapshot.data() as Map<String, dynamic>;
        List<dynamic> containerList = data['containers'] ?? [];
        _containers =
            containerList.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error fetching containers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Containers", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _containers.isEmpty
              ? const Center(
                  child: Text("No containers found for this problem."))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _containers.length,
                  itemBuilder: (context, index) {
                    final container = _containers[index];
                    final name =
                        container['containerName'] ?? 'Untitled Container';
                    final description = container['containerDescription'] ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      color: AppStyles.backgroundLight(),
                      child: ListTile(
                        title: Text(
                          name,
                          style: AppStyles.labelLarge(
                              color: AppStyles.onBackground()),
                        ),
                        subtitle: description.isNotEmpty
                            ? Text(
                                description,
                                style: AppStyles.labelSmall(
                                    color: AppStyles.onBackground()),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
