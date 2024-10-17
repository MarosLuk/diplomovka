import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/pages/features/app/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
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
    final userData = await ref.read(profileProvider.notifier).fetchUserData();
    setState(() {
      usernameController.text = userData['username'] ?? '';
      emailController.text = userData['email'] ?? '';
    });
  }

  void updateUserProfile() {
    String newEmail = emailController.text;
    String newUsername = usernameController.text;
    String newPassword = passwordController.text;

    ref.read(profileProvider.notifier).updateUserProfile(
          newUsername: newUsername,
          newEmail: newEmail,
          newPassword: newPassword,
        );
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
            colors: [AppStyles.backgroundLight(), AppStyles.background()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
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
                    backgroundColor: AppStyles.background().withOpacity(0.7),
                    child: Icon(Icons.person,
                        size: 50, color: AppStyles.onBackground()),
                  ),
                ),
                const SizedBox(height: 30),
                Text("Username",
                    style: AppStyles.labelLarge(
                        color: Theme.of(context).primaryColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).primaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      hintText: "Enter your username",
                      hintStyle: AppStyles.labelLarge(color: Colors.black54)),
                  style: AppStyles.labelLarge(
                      color: Theme.of(context).colorScheme.secondary),
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
                    fillColor: Theme.of(context).primaryColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    hintText: "Enter your email",
                    hintStyle: AppStyles.labelLarge(color: Colors.black54),
                  ),
                  style: AppStyles.labelLarge(
                      color: Theme.of(context).colorScheme.secondary),
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
                    fillColor: Theme.of(context).primaryColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    hintText: "Enter a new password",
                    hintStyle: AppStyles.labelLarge(color: Colors.black54),
                  ),
                  style: AppStyles.labelLarge(
                      color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: updateUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.backgroundLight(),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 60),
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
