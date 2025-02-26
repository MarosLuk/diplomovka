import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class ProblemDetailsPage extends StatefulWidget {
  final String problemId;
  final String problemName;

  const ProblemDetailsPage({
    Key? key,
    required this.problemId,
    required this.problemName,
  }) : super(key: key);

  @override
  _ProblemDetailsPageState createState() => _ProblemDetailsPageState();
}

class _ProblemDetailsPageState extends State<ProblemDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

  List<Map<String, dynamic>> containers = [];
  List<String> collaborators = [];

  @override
  void initState() {
    super.initState();
    _fetchProblemDetails();
  }

  Future<void> _fetchProblemDetails() async {
    try {
      DocumentSnapshot problemDoc =
          await _firestore.collection('problems').doc(widget.problemId).get();

      if (problemDoc.exists) {
        Map<String, dynamic> data = problemDoc.data() as Map<String, dynamic>;

        List<Map<String, dynamic>> fetchedContainers = [];
        if (data['containers'] != null) {
          fetchedContainers =
              List<Map<String, dynamic>>.from(data['containers']);
        }

        List<String> fetchedCollaborators = [];
        if (data['collaborators'] != null) {
          fetchedCollaborators = List<String>.from(data['collaborators']);
        }

        setState(() {
          containers = fetchedContainers;
          collaborators = fetchedCollaborators;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching problem details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteContainer(String containerId) async {
    try {
      setState(() => isLoading = true);

      DocumentReference problemRef =
          _firestore.collection('problems').doc(widget.problemId);

      await problemRef.update({
        'containers': FieldValue.arrayRemove(
            containers.where((c) => c['containerId'] == containerId).toList())
      });

      _fetchProblemDetails();
    } catch (e) {
      print("Error deleting container: $e");
    }
  }

  Future<void> _removeCollaborator(String email) async {
    try {
      setState(() => isLoading = true);

      DocumentReference problemRef =
          _firestore.collection('problems').doc(widget.problemId);

      await problemRef.update({
        'collaborators': FieldValue.arrayRemove([email])
      });

      _fetchProblemDetails();
    } catch (e) {
      print("Error removing collaborator: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.problemName,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        backgroundColor: AppStyles.backgroundLight(),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Containers',
                      containers,
                      isContainer: true,
                    ),
                    _buildSection(
                      'Collaborators',
                      collaborators.map((e) => {'email': e}).toList(),
                      isContainer: false,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items,
      {bool isContainer = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyles.titleMedium(
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Text(
                'No $title found',
                style: AppStyles.labelSmall(
                  color: AppStyles.backgroundLight(),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    color: AppStyles.backgroundLight(),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        isContainer
                            ? (item['containerName'] ?? 'Unnamed')
                            : item['email'] ?? 'Unknown',
                        style: AppStyles.titleSmall(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      subtitle: isContainer
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  'ID: ${item['containerId'] ?? 'Unknown'}',
                                  style: AppStyles.labelSmall(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'Generated By: ${item['generatedBy'] ?? 'Unknown'}',
                                  style: AppStyles.labelSmall(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (isContainer) {
                            _deleteContainer(item['containerId']);
                          } else {
                            _removeCollaborator(item['email']);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
        const SizedBox(height: 16),
      ],
    );
  }
}
