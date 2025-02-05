import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/secureStorage/secureStorageService.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Import your pages if needed: e.g. import 'package:fit_journey/pages/home/homePage.dart';
// But we won't navigate directly; we can use named routes.

class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _checkTokens();
  }

  Future<void> _checkTokens() async {
    // 1. Read the stored token + expiry
    final accessToken = await _secureStorage.getAccessToken();
    final accessTokenExpiry = await _secureStorage.getAccessTokenExpiry();

    // The widget might be disposed if the user left the screen
    if (!mounted) return;

    // 2. Decide if token is missing or expired
    final bool isMissingToken = (accessToken == null || accessToken.isEmpty);
    final bool isMissingExpiry = (accessTokenExpiry == null);
    final bool isExpired = accessTokenExpiry != null
        ? DateTime.now().isAfter(accessTokenExpiry)
        : true;

    await Future.delayed(const Duration(seconds: 2));

    if (isMissingToken || isMissingExpiry || isExpired) {
      // No token or it’s expired => go to login/landing
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Token is present and still valid => go to home/splash
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // While loading, just show a splash or loader
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF212121)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            const SizedBox(height: 24),
            Text(
              'Your Helpie',
              style: AppStyles.headLineLarge(color: Colors.white)
                  .copyWith(fontSize: 32),
            ),
            const Spacer(), // Spacer pushes the loading indicator to the bottom

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
