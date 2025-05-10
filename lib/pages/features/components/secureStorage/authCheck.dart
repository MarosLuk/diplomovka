import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/components/secureStorage/secureStorageService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

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
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final accessToken = await _secureStorage.getAccessToken();
    final accessTokenExpiry = await _secureStorage.getAccessTokenExpiry();
    final prefs = await SharedPreferences.getInstance();
    final int rememberMeStatus = prefs.getInt('rememberMe') ?? 0;

    if (!mounted) return;

    final bool isTokenMissing = (accessToken == null || accessToken.isEmpty);
    final bool isTokenExpired = accessTokenExpiry != null
        ? DateTime.now().isAfter(accessTokenExpiry)
        : true;

    await Future.delayed(const Duration(seconds: 2));

    if (isTokenMissing || isTokenExpired || rememberMeStatus == 0) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      if (rememberMeStatus == 2) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Your SoftHat',
              style: AppStyles.headLineLarge(color: Colors.white)
                  .copyWith(fontSize: 32),
            ),
            const Spacer(),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
