// signUpPage.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/pages/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/user_auth/secureStorage/secureStorageService.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.65,
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
                Icons.person_add,
                size: 80,
                color: AppStyles.onBackground(),
              ),
              const SizedBox(height: 20),
              Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.onBackground(),
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                  _usernameController, 'Username', Icons.person, false),
              const SizedBox(height: 10),
              _buildTextField(_emailController, 'Email', Icons.email, false),
              const SizedBox(height: 10),
              _buildTextField(
                  _passwordController, 'Password', Icons.lock, true),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _signUp();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppStyles.backgroundLight(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSigningUp
                        ? CircularProgressIndicator(
                            color: AppStyles.onBackground(),
                          )
                        : Text(
                            "Sign up",
                            style: TextStyle(
                              color: AppStyles.onBackground(),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: AppStyles.onBackground()),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, "/login");
                    },
                    child: Text(
                      "Login",
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

  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.endsWith("@admin.sk")) {
      setState(() {
        isSigningUp = false;
      });
      showToast(message: "You can't create new admin", isError: true);
      return;
    }

    User? user = await _auth.signUpWithEmailAndPassword(email, password);

    setState(() {
      isSigningUp = false;
    });

    if (user != null) {
      // Optionally, check that tokens have been stored:
      String? storedToken = await SecureStorageService().getAccessToken();
      print("Stored Access Token after signup: $storedToken");

      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'email': email,
      });

      showToast(message: "User is successfully created", isError: false);
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      print("Error occurred during sign up.");
    }
  }
}
