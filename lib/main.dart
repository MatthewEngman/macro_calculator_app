import 'package:flutter/material.dart';
import 'package:macro_masher/src/features/meal_plan/data/meal_plan_db.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macro_masher/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/persistence/database_helper.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/routing/navigation_provider.dart' as navigation;
import 'src/core/persistence/shared_preferences_provider.dart'
    as prefs_provider;
import 'src/core/persistence/database_provider.dart' as db_provider_impl;
import 'package:macro_masher/src/core/persistence/repository_providers.dart'
    as repo_providers;
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/auth/presentation/providers/auth_provider.dart'
    as auth_provider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Database? db;
  late FirebaseFirestore firestore;
  late FirebaseAuth auth;
  const int databaseVersion = 3; // Define your current DB version

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestore = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;

    // Initialize the database with a more aggressive approach
    try {
      print('Initializing database through DatabaseHelper...');

      // Force a clean database initialization
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'app_database.db');

      // Delete any existing database files to start fresh
      final dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
        print('Deleted existing database file during startup');
      }

      // Delete journal files
      final journalFile = File('$path-journal');
      if (await journalFile.exists()) {
        await journalFile.delete();
        print('Deleted journal file during startup');
      }

      final shmFile = File('$path-shm');
      if (await shmFile.exists()) {
        await shmFile.delete();
        print('Deleted shm file during startup');
      }

      final walFile = File('$path-wal');
      if (await walFile.exists()) {
        await walFile.delete();
        print('Deleted wal file during startup');
      }

      // Create the database with explicit parameters
      db = await openDatabase(
        path,
        version: databaseVersion,
        onCreate: (Database db, int version) async {
          print(
            'DatabaseHelper: Creating database tables for version $version',
          );

          // Create settings table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT,
              last_modified INTEGER
            )
          ''');
          print('DatabaseHelper: Created settings table');

          // Create users table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              firebase_user_id TEXT,
              name TEXT,
              age INTEGER,
              sex TEXT,
              weight REAL,
              feet INTEGER,
              inches REAL,
              activity_level TEXT,
              goal TEXT,
              units TEXT,
              weight_change_rate REAL DEFAULT 1.0,
              is_default INTEGER DEFAULT 0,
              created_at INTEGER,
              updated_at INTEGER,
              last_modified INTEGER
            )
          ''');
          print('DatabaseHelper: Created user table');

          // Create macro_calculations table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS macro_calculations (
              id TEXT PRIMARY KEY,
              user_id TEXT,
              calories REAL,
              protein REAL,
              carbs REAL,
              fat REAL,
              calculation_type TEXT,
              created_at INTEGER,
              updated_at INTEGER,
              is_default INTEGER DEFAULT 0,
              name TEXT,
              last_modified INTEGER,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          print('DatabaseHelper: Created macro_calculations table');

          // Create meal plans table
          await MealPlanDB.createTable(db);
          print('DatabaseHelper: Created meal plan table');

          // Create meal logs table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS meal_logs (
              id TEXT PRIMARY KEY,
              user_id TEXT,
              meal_plan_id TEXT,
              date TEXT,
              meal_type TEXT,
              food_item TEXT,
              calories REAL,
              protein REAL,
              carbs REAL,
              fat REAL,
              completed INTEGER DEFAULT 0,
              created_at INTEGER,
              updated_at INTEGER,
              last_modified INTEGER,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
              FOREIGN KEY (meal_plan_id) REFERENCES meal_plans (id) ON DELETE CASCADE
            )
          ''');
          print('DatabaseHelper: Created meal log table');

          print('DatabaseHelper: All tables created successfully');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          print(
            'DatabaseHelper: Upgrading database from v$oldVersion to v$newVersion',
          );

          if (oldVersion < 2) {
            // Add weight_change_rate column to users table if upgrading from v1
            await db.execute(
              'ALTER TABLE users ADD COLUMN weight_change_rate REAL DEFAULT 1.0',
            );
            print(
              'DatabaseHelper: Added weight_change_rate column to users table',
            );
          }

          if (oldVersion < 3) {
            // Add any schema changes for version 3
            print('DatabaseHelper: Applying version 3 schema changes');
          }
        },
        onConfigure: (Database db) async {
          print('DatabaseHelper: Configuring database...');

          // Use rawQuery for PRAGMA statements (execute doesn't work for PRAGMAs)
          await db.rawQuery('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = DELETE');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
          await db.rawQuery('PRAGMA locking_mode = NORMAL');
          await db.rawQuery('PRAGMA busy_timeout = 5000');

          print('DatabaseHelper: Database configured with pragmas');
        },
      );

      // Test write operations to verify database is writable
      final testId = DateTime.now().millisecondsSinceEpoch;

      // First drop the test table if it exists to avoid constraint violations
      try {
        await db.execute('DROP TABLE IF EXISTS _write_test_table');
      } catch (e) {
        print('Error dropping test table: $e');
        // Continue anyway
      }

      // Then create it fresh and test write operations
      await db.execute(
        'CREATE TABLE IF NOT EXISTS _write_test_table (id INTEGER PRIMARY KEY)',
      );
      await db.execute('INSERT INTO _write_test_table (id) VALUES ($testId)');
      await db.execute('DELETE FROM _write_test_table WHERE id = $testId');
      await db.execute('DROP TABLE IF EXISTS _write_test_table');
      print('Database write test successful');

      // Set the database in DatabaseHelper to ensure consistency
      DatabaseHelper.setDatabase(db);

      print('Database successfully initialized through DatabaseHelper');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow; // Rethrow to abort app initialization
    }

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Initialize GoRouter
    final router = appRouter; // Adjust if ref is needed early

    // Setup Riverpod providers
    final container = ProviderContainer(
      overrides: [
        prefs_provider.sharedPreferencesProvider.overrideWithValue(prefs),
        repo_providers.firebaseAuthProvider.overrideWithValue(auth),
        repo_providers.firestoreProvider.overrideWithValue(firestore),
        navigation.goRouterProvider.overrideWithValue(router),
        // Use the db instance created directly in main
        db_provider_impl.databaseProvider.overrideWithValue(db),
        // Services (these will now correctly use the overridden db via persistenceServiceProvider)
        repo_providers.localStorageServiceProvider,
        repo_providers.firestoreSyncServiceProvider,
      ],
    );

    // Initialize the auth state listener to handle onboarding
    container.read(auth_provider.authStateListenerProvider);

    // Start listening to auth changes to potentially trigger sync
    // container.read(repo_providers.dataSyncManagerProvider).listenToAuthChanges(); // Uncomment if used

    // Start background sync if applicable
    // await sync_service.startBackgroundSync(container); // Pass container if needed

    runApp(UncontrolledProviderScope(container: container, child: MyApp()));
  } catch (e, stacktrace) {
    print('FATAL: Database initialization failed in main: $e');
    print('Stacktrace: $stacktrace');
    // Handle critical error...
    db = null; // Ensure db is null on failure
  }

  // Ensure database is available before setting up dependent providers
  if (db == null) {
    print(
      "CRITICAL ERROR: Database is null, cannot proceed with provider setup.",
    );
    return; // Stop execution if DB failed
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the GoRouter instance from the provider
    final router = ref.watch(navigation.goRouterProvider);

    return MaterialApp.router(
      title: 'Macro Masher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: router, // Use routerConfig for GoRouter 6.x+
    );
  }
}
