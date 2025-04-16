import 'package:macro_masher/src/core/persistence/local_storage_service.dart';

import 'src/core/persistence/firestore_sync_service.dart';
import 'package:macro_masher/src/core/persistence/persistence_service.dart';
import 'package:macro_masher/src/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_info_repository_firestore_impl.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_info_repository_hybrid_impl.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_info_repository_sqlite_impl.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/profile_provider.dart';
import 'package:macro_masher/src/core/persistence/data_sync_manager.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/user_info_provider.dart';

import 'src/core/persistence/repository_providers.dart' as persistence;
import 'src/core/persistence/background_sync_service.dart' as sync_service;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_options.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/persistence/database_helper.dart';
import 'src/core/routing/navigation_provider.dart' as navigation;
import 'src/core/persistence/shared_preferences_provider.dart'
    as prefs_provider;
import 'src/features/calculator/presentation/providers/calculator_provider.dart';
import 'src/core/persistence/database_provider.dart' as db_provider_impl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize SQLite database
  final database = await DatabaseHelper.instance.database;

  // Initialize connectivity
  final connectivity = Connectivity();

  // Initialize the persistence service
  final persistenceService = PersistenceService(database);
  await persistenceService.initialize();

  // Initialize local storage service
  final localStorageService = LocalStorageService(persistenceService);

  // Initialize FirestoreSyncService with the local storage service
  await FirestoreSyncService.initialize(localStorageService);

  runApp(
    ProviderScope(
      overrides: [
        navigation.navigationProvider.overrideWithValue((route) {
          final context = appRouter.routerDelegate.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            context.go(route);
          }
        }),
        prefs_provider.sharedPreferencesProvider.overrideWithValue(prefs),
        // Override the database provider with the initialized database
        db_provider_impl.databaseProvider.overrideWithValue(database),
        // Override the profile repository provider
        profileRepositoryProvider.overrideWithValue(
          ProfileRepositoryImpl(prefs),
        ),
        // Override the profileProvider
        profileProvider.overrideWith((ref) {
          final repository = ref.watch(profileRepositoryProvider);
          return ProfileNotifier(repository);
        }),
        // Override the Firebase Auth provider
        persistence.firebaseAuthProvider.overrideWithValue(
          FirebaseAuth.instance,
        ),
        // Override the Firestore provider
        persistence.firestoreProvider.overrideWithValue(
          FirebaseFirestore.instance,
        ),
        // Override the connectivity provider
        persistence.connectivityProvider.overrideWithValue(connectivity),
        // Override the persistence service provider
        persistenceServiceProvider.overrideWithValue(persistenceService),
        // Override the data sync manager provider
        persistence.dataSyncManagerProvider.overrideWithValue(
          DataSyncManager(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
            connectivity,
          ),
        ),
        // Override the userInfoRepositoryProvider
        persistence.firestoreSyncServiceProvider.overrideWithValue(
          FirestoreSyncService(),
        ),
      ],
      child: const MacroCalculatorApp(),
    ),
  );
}

class MacroCalculatorApp extends ConsumerWidget {
  const MacroCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the background sync service
    ref.read(sync_service.backgroundSyncServiceProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
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
