import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            usernameController.text = userDoc.get('username');
            emailController.text = user!.email!;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        showToast(message: "Error fetching user data");
      }
    }
  }

  Future<void> updateUserProfile() async {
    String newEmail = emailController.text;
    String newUsername = usernameController.text;
    String newPassword = passwordController.text;

    try {
      QuerySnapshot emailCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: newEmail)
          .get();

      if (emailCheck.docs.isNotEmpty && user!.email != newEmail) {
        showToast(message: "Email already exists in the database.");
        return;
      }

      if (newEmail != user!.email) {
        await user!.updateEmail(newEmail);
      }

      if (newPassword.isNotEmpty) {
        await user!.updatePassword(newPassword);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'username': newUsername,
        'email': newEmail,
      });

      showToast(message: "Profile updated successfully");

      Navigator.pop(context, newUsername);
    } catch (e) {
      showToast(message: "Error updating profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: AppStyles.headLineMedium(
            color: Theme.of(context).primaryColor,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple[600]!, Colors.deepPurple[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurpleAccent.withOpacity(0.7),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),

                // Username Field
                Text("Username",
                    style: AppStyles.labelLarge(
                        color: Theme.of(context).primaryColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    hintText: "Enter your username",
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "Email",
                  style: AppStyles.labelLarge(
                      color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    hintText: "Enter your email",
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  "New Password",
                  style: AppStyles.labelLarge(
                      color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white70,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    hintText: "Enter a new password",
                  ),
                ),
                const SizedBox(height: 40),

                // Update Profile Button
                Center(
                  child: ElevatedButton(
                    onPressed: updateUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Update Profile",
                      style: AppStyles.labelLarge(
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
