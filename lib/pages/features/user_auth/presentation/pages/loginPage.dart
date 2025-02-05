// loginPage.dart
import 'package:diplomovka/pages/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:diplomovka/pages/features/user_auth/secureStorage/secureStorageService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  bool _rememberMe = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
  }

  Future<void> _checkRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe) {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, "/home");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80,
                color: AppStyles.onBackground(),
              ),
              const SizedBox(height: 20),
              _buildTextField(_emailController, 'Email', Icons.email, false),
              const SizedBox(height: 10),
              _buildTextField(
                  _passwordController, 'Password', Icons.lock, true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        checkColor: Colors.pinkAccent,
                        value: _rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      Text(
                        'Remember me',
                        style: AppStyles.labelSmall(
                            color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: AppStyles.labelSmall(
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _signIn();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppStyles.backgroundLight(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigning
                        ? CircularProgressIndicator(
                            color: AppStyles.onBackground())
                        : Text(
                            "Login",
                            style: AppStyles.titleMedium(
                                color: Theme.of(context).primaryColor),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: AppStyles.labelSmall(
                        color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, "/signUp");
                    },
                    child: Text(
                      "Sign Up",
                      style: AppStyles.titleMedium(color: Colors.pinkAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: AppStyles.onBackground()),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppStyles.background(),
        prefixIcon: Icon(icon, color: AppStyles.onBackground()),
        hintText: hintText,
        hintStyle: TextStyle(color: AppStyles.onBackground()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      User? user = await _auth.signInWithEmailAndPassword(email, password);
      setState(() {
        _isSigning = false;
      });

      if (user != null) {
        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', true);
        }

        String? storedToken = await SecureStorageService().getAccessToken();
        print("Stored Access Token: $storedToken");

        if (email.endsWith("@admin.sk")) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/admin",
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/home",
            (Route<dynamic> route) => false,
          );
        }
      } else {
        showToast(message: "Invalid email or password.", isError: true);
      }
    } catch (e) {
      setState(() {
        _isSigning = false;
      });
      showToast(message: "Error signing in: $e", isError: true);
    }
  }

  Future<void> _signInWithGoogle() async {
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken,
        );

        await _firebaseAuth.signInWithCredential(credential);
        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('rememberMe', true);
        }
        Navigator.pushReplacementNamed(context, "/home");
      }
    } catch (e) {
      showToast(message: "Some error occurred: $e", isError: true);
    }
  }
}
