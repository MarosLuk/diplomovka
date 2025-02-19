import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/userDetailPage.dart';
import 'dart:async';

class AdminSearchPage extends StatefulWidget {
  const AdminSearchPage({super.key});

  @override
  State<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends State<AdminSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _filteredUsers = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2) {
        _fetchUsers(query);
      } else {
        setState(() {
          _filteredUsers = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchUsers(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
        return {
          'email': doc['email'],
          'username': doc['username'],
          'uid': doc.id,
        };
      }).toList();

      setState(() {
        _filteredUsers = users;
      });
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Search',
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
              onChanged: _onSearchChanged,
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
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
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
                                      userId: user['uid'],
                                      email: user['email'],
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
