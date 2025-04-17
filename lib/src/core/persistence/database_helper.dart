import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/meal_plan/data/meal_plan_db.dart';
import '../../features/calculator/data/repositories/macro_calculation_db.dart';
import '../../features/profile/data/repositories/user_db.dart';
import '../../features/meal_plan/data/meal_log_db.dart';

class DatabaseHelper {
  static const _databaseName = "app_database.db";
  static const _databaseVersion =
      3; // Increased version for weight_change_rate column

  static const tableSettings = 'settings';
  static const columnKey = 'key';
  static const columnValue = 'value';

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database.
  static Database? _database;

  // Method to manually set the database instance from outside
  static void setDatabase(Database db) {
    _database = db;
    print('DatabaseHelper: Database instance set manually');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the db the first time it is accessed.
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database (and create it if it doesn't exist).
  Future<Database> _initDatabase() async {
    try {
      // Ensure the database directory exists
      final dbPath = await getDatabasesPath();
      final dbDirectory = Directory(dbPath);
      if (!await dbDirectory.exists()) {
        await dbDirectory.create(recursive: true);
      }

      // Full path to the database file
      String path = join(dbPath, _databaseName);

      // Check if the database file exists and is writable
      final file = File(path);
      if (await file.exists()) {
        try {
          // Try to open the file in write mode to check permissions
          final raf = await file.open(mode: FileMode.append);
          await raf.close();
        } catch (e) {
          // If we can't write to the file, delete it and recreate
          print('Database file exists but is not writable: $e');
          await file.delete();
          print('Deleted read-only database file, will recreate');
        }
      }

      // Open the database with explicit readOnly: false flag
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        readOnly: false,
        singleInstance: true,
      );

      // Set journal mode to WAL for better performance and concurrency
      await db.execute('PRAGMA journal_mode=WAL');
      await db.execute('PRAGMA foreign_keys=ON');

      print('Database successfully initialized in write mode');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      // Fallback to in-memory database if file-based database fails
      final db = await openDatabase(
        ':memory:',
        version: _databaseVersion,
        onCreate: _onCreate,
        readOnly: false,
      );
      print('Using in-memory database as fallback');
      return db;
    }
  }

  // SQL code to create the database table.
  static Future _onCreate(Database db, int version) async {
    print('DatabaseHelper: Creating database tables for version $version');
    try {
      await db.execute('''
          CREATE TABLE $tableSettings (
            $columnKey TEXT PRIMARY KEY,
            $columnValue TEXT NOT NULL
          )
          ''');
      print('DatabaseHelper: Created settings table');

      // Create tables
      await UserDB.createTable(db);
      print('DatabaseHelper: Created user table');

      await MealPlanDB.createTable(db);
      print('DatabaseHelper: Created meal plan table');

      await MealLogDB.createTable(db);
      print('DatabaseHelper: Created meal log table');

      print('DatabaseHelper: All tables created successfully');
    } catch (e, stack) {
      print('DatabaseHelper: Error creating tables: $e');
      print('DatabaseHelper: Stack trace: $stack');
      rethrow;
    }
  }

  // Handle database upgrades
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
      'DatabaseHelper: Upgrading database from version $oldVersion to $newVersion',
    );
    try {
      if (oldVersion < 2) {
        // Add new tables if upgrading from version 1
        if (!await _tableExists(db, UserDB.tableName)) {
          await UserDB.createTable(db);
          print('DatabaseHelper: Added user table during upgrade');
        }
        if (!await _tableExists(db, MealLogDB.tableName)) {
          await MealLogDB.createTable(db);
          print('DatabaseHelper: Added meal log table during upgrade');
        }
      }
      print('DatabaseHelper: Database upgrade completed successfully');
    } catch (e, stack) {
      print('DatabaseHelper: Error upgrading database: $e');
      print('DatabaseHelper: Stack trace: $stack');
      rethrow;
    }
  }

  // Helper method to check if a table exists
  static Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );
    return result.isNotEmpty;
  }
}
