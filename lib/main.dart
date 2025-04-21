import 'package:flutter/material.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Database? db;
  late FirebaseFirestore firestore;
  late FirebaseAuth auth;
  const int databaseVersion = 3; // Define your current DB version

  // Define onCreate logic directly in main
  Future<void> _onCreate(Database db, int version) async {
    print('main: Creating database tables for version $version');
    // Use DatabaseHelper constants to build the SQL
    await db.execute('''
      CREATE TABLE ${DatabaseHelper.tableSettings} (
        ${DatabaseHelper.columnKey} TEXT PRIMARY KEY,
        ${DatabaseHelper.columnValue} TEXT NOT NULL
      )
    ''');
    print('main: Created settings table');
    await UserDB.createTable(db);
    print('main: Created user table');
    await MealPlanDB.createTable(db);
    print('main: Created meal plan table');
    // await MealLogDB.createTable(db); // Assuming MealLogDB has createTable
    // print('main: Created meal log table');
    // Macro Calculation table (using constants from MacroCalculationDB)
    await db.execute('''
      CREATE TABLE ${MacroCalculationDB.tableName} (
        ${MacroCalculationDB.columnId} TEXT PRIMARY KEY,
        ${MacroCalculationDB.columnUserId} TEXT NOT NULL,
        ${MacroCalculationDB.columnCalories} REAL NOT NULL,
        ${MacroCalculationDB.columnProtein} REAL NOT NULL,
        ${MacroCalculationDB.columnCarbs} REAL NOT NULL,
        ${MacroCalculationDB.columnFat} REAL NOT NULL,
        ${MacroCalculationDB.columnCalculationType} TEXT,
        ${MacroCalculationDB.columnCreatedAt} INTEGER NOT NULL,
        ${MacroCalculationDB.columnUpdatedAt} INTEGER NOT NULL,
        ${MacroCalculationDB.columnIsDefault} INTEGER NOT NULL DEFAULT 0,
        ${MacroCalculationDB.columnName} TEXT,
        ${MacroCalculationDB.columnLastModified} INTEGER NOT NULL
      )
    ''');
    print('main: Created macro calculation table');
    print('main: All tables created successfully');
  }

  // Define onUpgrade logic directly in main (adapt as needed based on DatabaseHelper._onUpgrade)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('main: Upgrading database from version $oldVersion to $newVersion');
    // Add upgrade logic here if necessary, similar to DatabaseHelper._onUpgrade
    // Example: Check oldVersion and add missing tables/columns
    if (oldVersion < 3) {
      // Check if tables exist before creating if necessary
      // Example: if (!await _tableExists(db, UserDB.tableName)) { await UserDB.createTable(db); }
      // For simplicity now, assume onCreate handles missing tables okay on upgrade if structure changed
      print('main: Performing upgrade tasks for version 3...');
      // Add specific ALTER TABLE or CREATE TABLE IF NOT EXISTS commands if needed
    }
    print('main: Database upgrade check completed');
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firestore = FirebaseFirestore.instance;
    auth = FirebaseAuth.instance;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    // Force delete existing files
    final dbFile = File(path);
    final journalFile = File('$path-journal');
    final shmFile = File('$path-shm');
    final walFile = File('$path-wal');
    if (await dbFile.exists()) {
      print('Deleting existing database file...');
      await dbFile.delete();
    }
    if (await journalFile.exists()) {
      await journalFile.delete();
    }
    if (await shmFile.exists()) {
      await shmFile.delete();
    }
    if (await walFile.exists()) {
      await walFile.delete();
    }

    print('Initializing database directly in main...');
    // Call openDatabase directly
    db = await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      readOnly: false, // Explicitly ensure writable
      singleInstance: true,
    );
    print('Database initialized successfully in main.dart.');
    print('main.dart: Initialized DB HashCode: ${db.hashCode}');

    // Set the database instance for static access (still useful for direct calls if any)
    DatabaseHelper.setDatabase(
      db,
    ); // Keep this if DatabaseHelper is used elsewhere
    print('Database instances set for static access.');
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

  // Start listening to auth changes to potentially trigger sync
  // container.read(repo_providers.dataSyncManagerProvider).listenToAuthChanges(); // Uncomment if used

  // Start background sync if applicable
  // await sync_service.startBackgroundSync(container); // Pass container if needed

  runApp(UncontrolledProviderScope(container: container, child: MyApp()));
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
