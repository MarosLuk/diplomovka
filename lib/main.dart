// main.dart
import 'package:diplomovka/pages/features/user_auth/secureStorage/authCheck.dart';
import 'package:diplomovka/pages/features/user_auth/secureStorage/secureStorageService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/homePage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/signUpPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/loginPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/adminSearchPage.dart';
import 'package:diplomovka/pages/features/user_auth/presentation/pages/admin/adminHomePage.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Lock orientation if needed.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Control theme settings.
  bool _isDarkMode = false;

  // Track Firebase initialization.
  bool _isFirebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Get the remember me flag.
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool rememberMe = prefs.getBool('rememberMe') ?? false;
      print("Remember Me flag: $rememberMe");

      // Read tokens from secure storage.
      final accessToken = await SecureStorageService().getAccessToken();
      final accessTokenExpiry =
          await SecureStorageService().getAccessTokenExpiry();

      print("Access Token from secure storage: $accessToken");
      print("Access Token Expiry from secure storage: $accessTokenExpiry");

      final tokenExpired = accessTokenExpiry == null ||
          DateTime.now().isAfter(accessTokenExpiry);
      print("Token expired? $tokenExpired (Current time: ${DateTime.now()})");

      // Only navigate to home if rememberMe is true, token is valid, and a Firebase user exists.
      if (rememberMe &&
          !tokenExpired &&
          FirebaseAuth.instance.currentUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, "/home");
        });
      }

      // Mark Firebase as initialized regardless.
      setState(() {
        _isFirebaseInitialized = true;
      });
      print("Firebase initialized successfully");
    } catch (e) {
      print("Error initializing Firebase: $e");
      showToastLong(message: "Error initializing Firebase: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While Firebase is initializing, show a splash/loading screen.
    if (!_isFirebaseInitialized) {
      return MaterialApp(
        home: Scaffold(
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
        ),
      );
    }

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
                // Use AuthCheck as the initial route.
                initialRoute: '/',
                routes: {
                  // AuthCheck will read tokens from secure storage and route accordingly.
                  '/': (context) => const AuthCheck(),
                  '/home': (context) => const HomePage(),
                  '/login': (context) => const LoginPage(),
                  '/signUp': (context) => const SignUpPage(),
                  '/admin': (context) => const AdminHomePage(),
                  '/admin/search': (context) => const AdminSearchPage(),
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
