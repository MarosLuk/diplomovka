import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/homePage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/signUpPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/loginPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/adminSearchPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/adminHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase(context);
  }

  Future<void> _initializeFirebase(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool rememberMe = prefs.getBool('rememberMe') ?? false;

      User? currentUser = FirebaseAuth.instance.currentUser;

      if (rememberMe && currentUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentUser.email != null &&
              currentUser.email!.endsWith("@admin.sk")) {
            // Navigate to admin page
            Navigator.pushReplacementNamed(context, "/admin");
          } else {
            // Navigate to home page
            Navigator.pushReplacementNamed(context, "/home");
          }
        });
      }

      setState(() {
        _isLoggedIn = rememberMe && currentUser != null;
        _isFirebaseInitialized = true;
      });

      print("Firebase initialized successfully");
    } catch (e) {
      print("Error initializing Firebase: $e");
      showToast(message: "Error initializing Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                initialRoute: '/',
                routes: {
                  '/': (context) {
                    // Perform Firebase initialization after the MaterialApp is built
                    if (!_isFirebaseInitialized) {
                      _initializeFirebase(context);
                    }

                    return const LoginPage();
                  },
                  '/home': (context) => const HomePage(),
                  '/login': (context) => const LoginPage(),
                  '/signUp': (context) => const SignUpPage(),
                  "/admin": (context) => const AdminHomePage(),
                  "/admin/search": (context) => const AdminSearchPage(),
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
      primaryColor: AppStyles.onBackground(),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppStyles.onBackground(),
        secondary: AppStyles.background(),
      ),
      scaffoldBackgroundColor: AppStyles.background(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppStyles.background(),
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
          textStyle: AppStyles.labelLarge(color: AppStyles.onBackground()),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: AppStyles.backgroundDark(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppStyles.backgroundDark(),
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
