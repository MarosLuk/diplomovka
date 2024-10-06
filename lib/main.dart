import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:firebase_core/firebase_core.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/homePage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/signUpPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  bool _isFirebaseInitialized = false;
  bool _isLoggedIn = false; // Track the user's login status

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  // Check if the user selected "Remember me" and Firebase initialization
  Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase and check for "Remember me"
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool rememberMe = prefs.getBool('rememberMe') ?? false;
      setState(() {
        _isLoggedIn = rememberMe && FirebaseAuth.instance.currentUser != null;
        _isFirebaseInitialized = true;
      });
      print("Firebase initialized successfully");
    } catch (e) {
      print("Error initializing Firebase: $e");
      showToast(message: "Error initializing Firebase: $e");
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirebaseInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // If the user is already logged in, go directly to the HomePage
    return AnimatedTheme(
      data: _isDarkMode ? _darkTheme() : _lightTheme(),
      duration: const Duration(milliseconds: 300),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: MaterialApp(
                theme: _lightTheme(),
                darkTheme: _darkTheme(),
                themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
                initialRoute: _isLoggedIn
                    ? '/home'
                    : '/', // Redirect to home if logged in
                routes: {
                  '/': (context) => const LoginPage(),
                  '/home': (context) => const HomePage(),
                  '/login': (context) => const LoginPage(),
                  '/signUp': (context) => const SignUpPage(),
                },
              ),
            ),
          );
        },
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: Colors.white, // Primary color
        secondary: Colors.deepPurple[900],
      ),
      scaffoldBackgroundColor: Colors.deepPurple[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple[900],
        iconTheme: IconThemeData(color: AppStyles.onBackground()),
      ),
      textTheme: TextTheme(
        headlineLarge: AppStyles.headLineLarge(color: AppStyles.onBackground()),
        headlineMedium:
            AppStyles.headLineMedium(color: AppStyles.onBackground()),
        headlineSmall: AppStyles.headLineSmall(color: AppStyles.onBackground()),
        titleMedium: AppStyles.titleMedium(color: AppStyles.onBackground()),
        bodyLarge: AppStyles.bodyLarge(color: AppStyles.onBackground()),
        bodyMedium: AppStyles.bodyMedium(color: AppStyles.onBackground()),
        labelLarge: AppStyles.labelLarge(color: AppStyles.onBackground()),
        labelMedium: AppStyles.labelMedium(color: AppStyles.onBackground()),
        labelSmall: AppStyles.labelSmall(color: AppStyles.onBackground()),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          textStyle: AppStyles.labelLarge(color: Colors.white),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: AppStyles.BackgroundDark(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppStyles.BackgroundDark(),
        iconTheme: IconThemeData(color: AppStyles.whiteDark()),
      ),
      textTheme: TextTheme(
        headlineLarge: AppStyles.headLineLarge(color: AppStyles.whiteDark()),
        headlineMedium: AppStyles.headLineMedium(color: AppStyles.whiteDark()),
        headlineSmall: AppStyles.headLineSmall(color: AppStyles.whiteDark()),
        titleMedium: AppStyles.titleMedium(color: AppStyles.whiteDark()),
        bodyLarge: AppStyles.bodyLarge(color: AppStyles.whiteDark()),
        bodyMedium: AppStyles.bodyMedium(color: AppStyles.whiteDark()),
        labelLarge: AppStyles.labelLarge(color: AppStyles.whiteDark()),
        labelMedium: AppStyles.labelMedium(color: AppStyles.whiteDark()),
        labelSmall: AppStyles.labelSmall(color: AppStyles.whiteDark()),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          textStyle: AppStyles.labelLarge(color: AppStyles.whiteDark()),
        ),
      ),
    );
  }
}
