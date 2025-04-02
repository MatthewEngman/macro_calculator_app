import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite
import 'src/core/routing/app_router.dart';
import 'src/core/persistence/database_helper.dart'; // Import DB Helper
// Import the provider definition file
import 'src/features/calculator/presentation/providers/calculator_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  final database = await DatabaseHelper.instance.database;

  runApp(
    ProviderScope(
      overrides: [
        // Override the Database provider with the initialized instance
        databaseProvider.overrideWithValue(database),
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
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.indigo, width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 12.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all( // Use WidgetStateProperty for newer Flutter versions
            Colors.indigo,
          ),
        ),
        // dropdownMenuTheme might not be needed if using DropdownButtonFormField
        // dropdownMenuTheme: const DropdownMenuThemeData(
        //   textStyle: TextStyle(fontSize: 16),
        // ),
      ),
    );
  }
}
