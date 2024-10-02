import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'assets/colorsStyles/testStyles.dart';

import 'package:diplomovka/assets/dataClasses/onboardingData.dart';

void main() {
  // Lock the orientation to portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
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
              constraints: const BoxConstraints(
                  maxWidth: 600), // Set the maximum width here
              child: MaterialApp(
                theme: _lightTheme(),
                darkTheme: _darkTheme(),
                themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
                initialRoute: '/',
                routes: {
                  //'/': (context) => const LandingPage(),
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
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: AppStyles.Background(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppStyles.Background(),
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
