import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import sqflite
import 'src/core/routing/app_router.dart';
import 'src/core/persistence/database_helper.dart'; // Import DB Helper
// Import the provider definition file
import 'src/features/calculator/presentation/providers/calculator_provider.dart';
import 'src/features/profile/data/repositories/profile_repository_impl.dart';
import 'src/features/profile/presentation/providers/profile_provider.dart';
import 'src/features/profile/presentation/providers/settings_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database and SharedPreferences
  final database = await DatabaseHelper.instance.database;
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override the Database provider with the initialized instance
        databaseProvider.overrideWithValue(database),
        // Override the ProfileRepository provider with the initialized instance
        profileRepositoryProvider.overrideWithValue(
          ProfileRepositoryImpl(sharedPreferences),
        ),
        // Override the SharedPreferences provider with the initialized instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter, // Use the router
      title: 'Macro Masher',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
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
          seedColor: Colors.indigo,
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
