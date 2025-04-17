import 'package:flutter/material.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'src/core/persistence/background_sync_service.dart' as sync_service;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:macro_masher/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';

import 'src/core/persistence/database_helper.dart';
import 'src/core/persistence/local_storage_service.dart';
import 'src/core/persistence/persistence_service.dart';
import 'src/core/persistence/data_sync_manager.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/routing/navigation_provider.dart' as navigation;
import 'src/core/persistence/shared_preferences_provider.dart'
    as prefs_provider;
import 'src/features/calculator/presentation/providers/calculator_provider.dart';
import 'src/core/persistence/database_provider.dart' as db_provider_impl;
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart'
    as repo_providers;
import 'src/features/profile/presentation/providers/profile_provider.dart'
    as profile_providers;
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/meal_plan/data/meal_plan_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Auth
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Initialize Firestore
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Force delete any existing database to ensure we start fresh
  try {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, 'app_database.db'));

    if (await dbFile.exists()) {
      print('Deleting existing database file');
      await dbFile.delete();
    }

    // Ensure the directory exists and is writable
    final dbDir = Directory(dbPath);
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    // Test write permissions
    final testFile = File(join(dbPath, 'test_write.txt'));
    await testFile.writeAsString('test');
    await testFile.delete();

    print('Database directory is writable');
  } catch (e) {
    print('Error preparing database directory: $e');
  }

  // Initialize the database manually to ensure it's writable
  Database? db;
  try {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    print('Opening database at: $path');

    // Open the database with explicit write mode
    db = await openDatabase(
      path,
      version: 4,
      onCreate: (Database db, int version) async {
        print('Creating database tables for version $version');
        try {
          // Create settings table
          await db.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          print('Created settings table');

          // Create meal plan table
          await db.execute('''
            CREATE TABLE meal_plans (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              is_default INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          print('Created meal plan table');

          // Create user table with weight_change_rate column
          await db.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              firebase_user_id TEXT NOT NULL,
              weight REAL,
              feet INTEGER,
              inches INTEGER,
              age INTEGER,
              sex TEXT NOT NULL,
              activity_level INTEGER NOT NULL,
              goal INTEGER NOT NULL,
              units INTEGER NOT NULL,
              name TEXT,
              is_default INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              last_modified INTEGER,
              weight_change_rate REAL DEFAULT 1.0
            )
          ''');
          print('Created user table');

          // Create macro calculation table
          await db.execute('''
            CREATE TABLE macro_calculations (
              id TEXT PRIMARY KEY,
              user_id TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              name TEXT,
              is_default INTEGER NOT NULL DEFAULT 0,
              calculation_type INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              last_modified INTEGER,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          print('Created macro calculation table');

          // Create meal log table
          await db.execute('''
            CREATE TABLE meal_logs (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              date TEXT NOT NULL,
              meal_type INTEGER NOT NULL,
              food_name TEXT NOT NULL,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          print('Created meal log table');

          print('All tables created successfully');
        } catch (e, stack) {
          print('Error creating tables: $e');
          print('Stack trace: $stack');
          rethrow;
        }
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        print('Upgrading database from version $oldVersion to $newVersion');
        try {
          if (oldVersion < 2) {
            // Add new tables if upgrading from version 1
            print('Upgrading from version 1 to 2');

            // Check if users table exists
            var tables = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='users'",
            );
            if (tables.isEmpty) {
              await db.execute('''
                CREATE TABLE users (
                  id TEXT PRIMARY KEY,
                  firebase_user_id TEXT NOT NULL,
                  weight REAL,
                  feet INTEGER,
                  inches INTEGER,
                  age INTEGER,
                  sex TEXT NOT NULL,
                  activity_level INTEGER NOT NULL,
                  goal INTEGER NOT NULL,
                  units INTEGER NOT NULL,
                  name TEXT,
                  is_default INTEGER NOT NULL DEFAULT 0,
                  created_at INTEGER NOT NULL,
                  updated_at INTEGER NOT NULL,
                  last_modified INTEGER
                )
              ''');
              print('Added users table during upgrade');
            }

            // Check if macro_calculations table exists
            tables = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='macro_calculations'",
            );
            if (tables.isEmpty) {
              await db.execute('''
                CREATE TABLE macro_calculations (
                  id TEXT PRIMARY KEY,
                  user_id TEXT,
                  calories REAL NOT NULL,
                  protein REAL NOT NULL,
                  carbs REAL NOT NULL,
                  fat REAL NOT NULL,
                  name TEXT,
                  is_default INTEGER NOT NULL DEFAULT 0,
                  calculation_type INTEGER NOT NULL,
                  created_at INTEGER NOT NULL,
                  updated_at INTEGER NOT NULL,
                  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                )
              ''');
              print('Added macro_calculations table during upgrade');
            }

            // Check if meal_logs table exists
            tables = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='meal_logs'",
            );
            if (tables.isEmpty) {
              await db.execute('''
                CREATE TABLE meal_logs (
                  id TEXT PRIMARY KEY,
                  user_id TEXT NOT NULL,
                  date TEXT NOT NULL,
                  meal_type INTEGER NOT NULL,
                  food_name TEXT NOT NULL,
                  calories REAL NOT NULL,
                  protein REAL NOT NULL,
                  carbs REAL NOT NULL,
                  fat REAL NOT NULL,
                  created_at INTEGER NOT NULL,
                  updated_at INTEGER NOT NULL,
                  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
                )
              ''');
              print('Added meal_logs table during upgrade');
            }
          }

          // Add weight_change_rate column to users table if upgrading to version 3
          if (oldVersion < 3) {
            print('Upgrading from version 2 to 3');

            // Check if the column already exists to avoid errors
            final tableInfo = await db.rawQuery("PRAGMA table_info(users)");
            final columnExists = tableInfo.any(
              (column) => column['name'] == 'weight_change_rate',
            );

            if (!columnExists) {
              await db.execute(
                'ALTER TABLE users ADD COLUMN weight_change_rate REAL DEFAULT 1.0',
              );
              print('Added weight_change_rate column to users table');
            }
          }

          // Add last_modified column to macro_calculations table if upgrading to version 4
          if (oldVersion < 4) {
            print('Upgrading from version 3 to 4');

            // Check if the column already exists to avoid errors
            final tableInfo = await db.rawQuery(
              "PRAGMA table_info(macro_calculations)",
            );
            final columnExists = tableInfo.any(
              (column) => column['name'] == 'last_modified',
            );

            if (!columnExists) {
              await db.execute(
                'ALTER TABLE macro_calculations ADD COLUMN last_modified INTEGER',
              );
              print('Added last_modified column to macro_calculations table');
            }
          }

          print('Database upgrade completed successfully');
        } catch (e, stack) {
          print('Error upgrading database: $e');
          print('Stack trace: $stack');
          rethrow;
        }
      },
      readOnly: false,
      singleInstance: true,
    );

    if (db != null) {
      print('Database HashCode in main: ${db.hashCode}');
      // Set the database instance in both DatabaseHelper and UserDB
      DatabaseHelper.setDatabase(db);
      UserDB.setDatabase(db);
      MacroCalculationDB.setDatabase(db);
      MealPlanDB.setDatabase(db);
      print(
        'Database instance set for UserDB, MacroCalculationDB and MealPlanDB',
      );
    }

    print('Database initialized successfully');
  } catch (e) {
    print('Error initializing database: $e');
    // Optionally handle the error more gracefully, e.g., show an error message and exit
  }

  // Check if database initialization failed
  if (db == null) {
    print('FATAL: Database could not be initialized. Exiting.');
    // Depending on the platform, you might exit or show a critical error UI
    // For now, let's throw an exception to halt execution
    throw Exception('Database initialization failed');
  }

  // Initialize connectivity
  final connectivity = Connectivity();

  // Initialize the persistence service
  final persistenceService = PersistenceService(db);
  await persistenceService.initialize();

  // Initialize local storage service
  final localStorageService = LocalStorageService(persistenceService);

  // Optionally, if FirestoreSyncService has an async static initializer:
  await FirestoreSyncService.initialize(localStorageService);

  // Create the FirestoreSyncService instance for provider override
  final firestoreSyncService = FirestoreSyncService();

  runApp(
    ProviderScope(
      overrides: [
        // NavigationProvider override using GoRouter
        navigation.navigationProvider.overrideWithValue((route) {
          final context = appRouter.routerDelegate.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            context.go(route);
          }
        }),
        repo_providers.firestoreSyncServiceProvider.overrideWithValue(
          firestoreSyncService,
        ),
        prefs_provider.sharedPreferencesProvider.overrideWithValue(prefs),
        // Override the database provider with the initialized database
        db_provider_impl.databaseProvider.overrideWithValue(db),
        // Override the profile repository provider
        profile_providers.profileRepositoryProvider.overrideWith(
          (ref) => ref.watch(repo_providers.profileRepositorySyncProvider),
        ),
        // Override the profileProvider
        profile_providers.profileProvider.overrideWith((ref) {
          final repository = ref.watch(
            profile_providers.profileRepositoryProvider,
          );
          return profile_providers.ProfileNotifier(repository);
        }),
        // Override the Firebase Auth provider
        repo_providers.firebaseAuthProvider.overrideWithValue(
          FirebaseAuth.instance,
        ),
        // Override the Firestore provider
        repo_providers.firestoreProvider.overrideWithValue(
          FirebaseFirestore.instance,
        ),
        // Override the connectivity provider
        repo_providers.connectivityProvider.overrideWithValue(connectivity),
        // Override the persistence service provider
        persistenceServiceProvider.overrideWithValue(persistenceService),
        // Override the data sync manager provider
        repo_providers.dataSyncManagerProvider.overrideWithValue(
          DataSyncManager(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
            connectivity,
          ),
        ),
        // Add any other overrides as needed...
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
      // Optionally, if you use navigatorKey elsewhere:
      // navigatorKey: appRouter.routerDelegate.navigatorKey,
      // ...other properties...
    );
  }
}
