import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/adminProblemDetail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool isLoading = true;
  bool isUpdating = false;

  List<Map<String, dynamic>> ownedProblems = [];
  List<Map<String, dynamic>> collaboratedProblems = [];
  List<Map<String, dynamic>> invites = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        _emailController.text = userDoc['email'];
        _usernameController.text = userDoc['username'];
      }

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

      QuerySnapshot invitesSnapshot = await _firestore
          .collection('invites')
          .where('invitedEmail', isEqualTo: widget.email)
          .get();

      List<Map<String, dynamic>> invitesList = invitesSnapshot.docs.map((doc) {
        return {
          'problemId': doc['problemId'],
          'problemName': doc['problemName'],
          'invitedBy': doc['invitedBy'],
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

  Future<void> _updateUserDetails() async {
    setState(() {
      isUpdating = true;
    });

    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'email': _emailController.text,
        'username': _usernameController.text,
      });
      if (_passwordController.text.isNotEmpty) {
        User? user = _auth.currentUser;

        if (user != null) {
          bool reauthenticated = await _reauthenticateUser(user);
          if (reauthenticated) {
            await user.updatePassword(_passwordController.text);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User password updated successfully!')),
            );
          } else {
            throw FirebaseAuthException(
              code: 'requires-recent-login',
              message: 'User re-authentication failed!',
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User details updated successfully!')),
      );
    } catch (e) {
      print("Error updating user details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user details: $e')),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<bool> _reauthenticateUser(User user) async {
    try {
      String? currentPassword = await _showReauthDialog();

      if (currentPassword != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Re-authentication error: $e");
      return false;
    }
  }

  Future<String?> _showReauthDialog() async {
    TextEditingController passwordController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppStyles.Primary50(),
          title: Text("Re-authenticate User"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Enter Current Password",
              filled: true,
              fillColor: AppStyles.backgroundLight(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, passwordController.text);
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkEmailInFirestore(String email) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final query = await usersRef.where('email', isEqualTo: email).get();

    if (query.docs.isNotEmpty) {
      print("Email exists in Firestore.");
    } else {
      print("Email not found in Firestore.");
    }
  }

  Future<void> _verifyAndSendPasswordReset() async {
    final email = _emailController.text.trim().toLowerCase();

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    print("Password reset email sent to $email");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Password reset email sent to $email")),
    );
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
                    _buildEditableField('Email', _emailController),
                    _buildEditableField('Username', _usernameController),
                    //_buildEditableField('New Password', _passwordController,
                    //isPassword: true),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isUpdating ? null : _updateUserDetails,
                      child: isUpdating
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Save Changes'),
                    ),
                    const SizedBox(height: 20),
                    _buildSection('Owned Hats', ownedProblems),
                    _buildSection('Collaborated Hats', collaboratedProblems),
                    _buildSection('Invites', invites),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPasswordField() {
    bool obscureText = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Password',
              style: AppStyles.titleMedium(
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: obscureText,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppStyles.backgroundLight(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.lock_reset,
                        color: Colors.red,
                      ),
                      onPressed: _verifyAndSendPasswordReset,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool isPassword = false}) {
    bool obscureText = isPassword;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppStyles.titleMedium(
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppStyles.backgroundLight(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
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
                        'Name: ' + item['problemName'],
                        style: AppStyles.titleSmall(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      subtitle: Text(
                        'Term ID: ${item['problemId']}',
                        style: AppStyles.labelSmall(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onTap: () {
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
