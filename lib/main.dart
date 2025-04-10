import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/persistence/database_helper.dart';
// Import the provider definition file
import 'src/features/profile/presentation/providers/settings_provider.dart';
import 'src/features/calculator/presentation/providers/calculator_provider.dart';
import 'src/features/profile/presentation/providers/profile_provider.dart';
import 'src/features/profile/data/repositories/profile_repository_impl.dart';
import 'src/features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize SQLite database
  final Database database = await DatabaseHelper.instance.database;

  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the instance
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Override the database provider with the initialized database
        databaseProvider.overrideWithValue(database),
        // Override the profile repository provider
        profileRepositoryProvider.overrideWithValue(
          ProfileRepositoryImpl(prefs),
        ),
        // Override the Firebase Auth provider
        firebaseAuthProvider.overrideWithValue(FirebaseAuth.instance),
        // Note: We're not overriding userInfoRepositoryProvider anymore
        // as it now uses Firestore directly
      ],
      child: const MacroCalculatorApp(),
    ),
  );
}

class MacroCalculatorApp extends ConsumerWidget {
  const MacroCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the auth state listener
    ref.watch(authStateListenerProvider);

    return MaterialApp.router(
      routerConfig: appRouter, // Use the router
      title: 'Macro Masher',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F82C3),
          brightness: Brightness.light,
        ),
        // Typography using M3 type system
        textTheme: TextTheme(
          displayLarge: const TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: const TextStyle(fontSize: 16),
        ),
        // Input decoration theme that uses ColorScheme colors
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 12.0,
          ),
        ),
        // Button theme that uses ColorScheme colors automatically
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
          ),
        ),
        // Radio theme that uses ColorScheme colors
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return null; // Use default disabled color from theme
            }
            return null; // Use primary color from ColorScheme
          }),
        ),
      ),
      // Add dark theme support using the same seed color
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 15, 130, 195),
          brightness: Brightness.dark,
        ),
        // Typography using M3 type system
        textTheme: TextTheme(
          displayLarge: const TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: const TextStyle(fontSize: 16),
        ),
        // Input decoration theme that uses ColorScheme colors
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 12.0,
          ),
        ),
        // Button theme that uses ColorScheme colors automatically
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 18)),
          ),
        ),
        // Radio theme that uses ColorScheme colors
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return null; // Use default disabled color from theme
            }
            return null; // Use primary color from ColorScheme
          }),
        ),
      ),
      // Use system theme mode by default
      themeMode: ThemeMode.system,
    );
  }
}
