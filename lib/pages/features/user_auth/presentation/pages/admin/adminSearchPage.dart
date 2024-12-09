import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/userDetailPage.dart';

class AdminSearchPage extends StatefulWidget {
  const AdminSearchPage({super.key});

  @override
  State<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends State<AdminSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
        return {
          'email': doc['email'],
          'username': doc['username'],
          'uid': doc.id,
        };
      }).toList();

      setState(() {
        _users = users;
        _filteredUsers = users;
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        final email = user['email'].toLowerCase();
        return email.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User search',
          style: AppStyles.headLineMedium(
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: AppStyles.backgroundLight(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                labelText: 'Search by email',
                prefixIcon: Icon(Icons.search, color: AppStyles.onBackground()),
                filled: true,
                fillColor: AppStyles.backgroundLight(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: AppStyles.titleMedium(
                          color: AppStyles.backgroundLight(),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Card(
                          color: AppStyles.backgroundLight(),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              user['email'],
                              style: AppStyles.labelSmall(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            subtitle: Text(
                              user['username'],
                              style: AppStyles.titleSmall(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onTap: () {
                              // Navigate to UserDetailsPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailsPage(
                                    userId: user['uid'], // Pass the user ID
                                    email: user['email'], // Pass the email
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
