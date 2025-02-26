import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppStyles.background(),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Users'),
              onTap: () {
                Navigator.pushNamed(context, '/admin/search');
              },
            ),
            ListTile(
              leading: const Icon(Icons.query_stats),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pushNamed(context, '/statistics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Settings'),
                    backgroundColor: AppStyles.Primary50(),
                    content:
                        const Text('Settings functionality to be implemented.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('rememberMe', 0);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (Route<dynamic> route) => false,
                );

                showToast(message: "Successfully signed out", isError: false);
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          "Welcome to the Admin Dashboard",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
