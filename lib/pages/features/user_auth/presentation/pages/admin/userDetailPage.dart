import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String email;

  const UserDetailsPage({Key? key, required this.userId, required this.email})
      : super(key: key);

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> ownedProblems = [];
  List<Map<String, dynamic>> collaboratedProblems = [];
  List<Map<String, dynamic>> invites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      // Fetch owned problems
      QuerySnapshot ownedSnapshot = await _firestore
          .collection('problems')
          .where('userId', isEqualTo: widget.userId)
          .get();

      List<Map<String, dynamic>> owned = ownedSnapshot.docs.map((doc) {
        return {
          'problemName': doc['problemName'],
          'problemId': doc.id,
        };
      }).toList();

      // Fetch collaborated problems
      QuerySnapshot collaboratedSnapshot = await _firestore
          .collection('problems')
          .where('collaborators', arrayContains: widget.email)
          .get();

      List<Map<String, dynamic>> collaborated =
          collaboratedSnapshot.docs.map((doc) {
        return {
          'problemName': doc['problemName'],
          'problemId': doc.id,
        };
      }).toList();

      // Fetch invites
      QuerySnapshot invitesSnapshot = await _firestore
          .collection('invites')
          .where('email', isEqualTo: widget.email)
          .get();

      List<Map<String, dynamic>> invitesList = invitesSnapshot.docs.map((doc) {
        return {
          'problemId': doc['problemId'],
          'problemName': doc['problemName'],
        };
      }).toList();

      setState(() {
        ownedProblems = owned;
        collaboratedProblems = collaborated;
        invites = invitesList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Details',
          style: AppStyles.headLineMedium(
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: AppStyles.backgroundLight(),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Owned Problems',
                      ownedProblems,
                    ),
                    _buildSection(
                      'Collaborated Problems',
                      collaboratedProblems,
                    ),
                    _buildSection(
                      'Invites',
                      invites,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
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
                        item['problemName'],
                        style: AppStyles.labelSmall(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      subtitle: Text(
                        'Problem ID: ${item['problemId']}',
                        style: AppStyles.titleSmall(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onTap: () {
                        // Navigate to the problem details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProblemDetailsPage(
                              problemId: item['problemId'],
                              problemName: item['problemName'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ProblemDetailsPage extends StatelessWidget {
  final String problemId;
  final String problemName;

  const ProblemDetailsPage({
    Key? key,
    required this.problemId,
    required this.problemName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          problemName,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        backgroundColor: AppStyles.backgroundLight(),
      ),
      body: Center(
        child: Text(
          'Details of $problemName (ID: $problemId)',
          style: AppStyles.titleMedium(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
