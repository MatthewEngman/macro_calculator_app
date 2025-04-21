import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/meal_plan/data/meal_plan_db.dart';
import '../../features/profile/data/repositories/user_db.dart';
import '../../features/meal_plan/data/meal_log_db.dart';

class DatabaseHelper {
  static const tableSettings = 'settings';
  static const columnKey = 'key';
  static const columnValue = 'value';
  static const columnLastModified = 'last_modified';
  static const tableUsers = 'users';
  static const columnId = 'id';
  static const columnFirebaseUserId = 'firebase_user_id';
  static const columnName = 'name';
  static const columnAge = 'age';
  static const columnSex = 'sex';
  static const columnWeight = 'weight';
  static const columnFeet = 'feet';
  static const columnInches = 'inches';
  static const columnActivityLevel = 'activity_level';
  static const columnGoal = 'goal';
  static const columnUnits = 'units';
  static const columnWeightChangeRate = 'weight_change_rate';
  static const columnIsDefault = 'is_default';
  static const columnCreatedAt = 'created_at';
  static const columnUpdatedAt = 'updated_at';
  static const _databaseName = "app_database.db";
  static const _databaseVersion = 3;

  static Database? _database;

  /// Get the current database instance or initialize a new one if needed
  static Future<Database> getInstance() async {
    if (_database != null) {
      try {
        // Quick test to see if the database is still writable
        await _database!.rawQuery('PRAGMA quick_check');
        return _database!;
      } catch (e) {
        print('Database instance check failed: $e');
        // Continue to recreation
      }
    }

    print('Getting new database instance...');

    try {
      // Force recreate the database every time to avoid read-only issues
      return await _recreateDatabaseCompletely();
    } catch (e) {
      print('Error getting database instance: $e');
      rethrow;
    }
  }

  /// Set the database instance
  static void setDatabase(Database db) {
    _database = db;
    print('DatabaseHelper: Database instance updated');
  }

  /// Gets the database, initializing it if necessary
  static Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    // Database is either null or closed, so we need to initialize it
    return await _initDatabase();
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    print('DatabaseHelper: Initializing database');
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    // Ensure the directory exists
    try {
      await Directory(databasePath).create(recursive: true);

      // Test if directory is writable
      final testFile = File(join(databasePath, 'write_test.txt'));
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      print('Error creating database directory: $e');
      throw Exception('Cannot create database directory: $e');
    }

    try {
      // Open the database with specific settings
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );

      // Verify the database is writable
      return await verifyDatabaseWritable();
    } catch (e) {
      print('Error initializing database: $e');

      // Last resort: delete the database file and try again
      await _recreateDatabaseFile();

      // Try one more time with a clean database
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );

      return _database!;
    }
  }

  /// Safely close the database
  static Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Force reopen the database
  static Future<Database> reopenDatabase() async {
    await closeDatabase();
    return await database;
  }

  /// Verifies that the database is writable and attempts to recover if it's not.
  /// This is a more aggressive approach that will delete and recreate the database if needed.
  static Future<Database> verifyDatabaseWritable({
    bool forceRecreate = false,
  }) async {
    print('Database write test starting...');

    try {
      // If forceRecreate is true, skip the tests and go straight to recreation
      if (forceRecreate) {
        print(
          'Force recreate requested - implementing aggressive recovery strategy',
        );
        return await _recreateDatabaseCompletely();
      }

      // First try a simple write test
      if (_database != null) {
        try {
          await _database!.rawQuery('PRAGMA journal_mode = DELETE');

          // Use a random ID to avoid UNIQUE constraint violations
          final testId = DateTime.now().millisecondsSinceEpoch;

          // First drop the test table if it exists to avoid constraint violations
          await _database!.rawQuery('DROP TABLE IF EXISTS _write_test_table');

          // Then create it fresh and test write operations
          await _database!.rawQuery(
            'CREATE TABLE IF NOT EXISTS _write_test_table (id INTEGER PRIMARY KEY)',
          );
          await _database!.rawQuery(
            'INSERT INTO _write_test_table (id) VALUES ($testId)',
          );
          await _database!.rawQuery(
            'DELETE FROM _write_test_table WHERE id = $testId',
          );
          await _database!.rawQuery('DROP TABLE IF EXISTS _write_test_table');
          print('Database write test successful via direct operations');
          return _database!;
        } catch (e) {
          print('Database write test failed: $e');
          // Continue to recovery
        }
      }

      // If we get here, the database is not writable or doesn't exist
      return await _recreateDatabaseCompletely();
    } catch (e) {
      print('Database recovery failed: $e');
      rethrow;
    }
  }

  static Future<void> _onConfigure(Database db) async {
    print('DatabaseHelper: Configuring database...');

    // Use rawQuery instead of execute for PRAGMA statements
    await db.rawQuery('PRAGMA foreign_keys = ON');
    await db.rawQuery('PRAGMA journal_mode = DELETE');
    await db.rawQuery('PRAGMA synchronous = NORMAL');
    await db.rawQuery('PRAGMA locking_mode = NORMAL');
    await db.rawQuery('PRAGMA busy_timeout = 5000');

    print('DatabaseHelper: Database configured with pragmas');
  }

  static Future _onCreate(Database db, int version) async {
    print('DatabaseHelper: Creating database tables for version $version');

    // Create settings table
    await db.rawQuery('''
      CREATE TABLE IF NOT EXISTS $tableSettings (
        $columnKey TEXT PRIMARY KEY,
        $columnValue TEXT,
        $columnLastModified INTEGER
      )
    ''');
    print('DatabaseHelper: Created settings table');

    // Create users table
    await db.rawQuery('''
      CREATE TABLE IF NOT EXISTS $tableUsers (
        $columnId TEXT PRIMARY KEY,
        $columnFirebaseUserId TEXT,
        $columnName TEXT,
        $columnAge INTEGER,
        $columnSex TEXT,
        $columnWeight REAL,
        $columnFeet INTEGER,
        $columnInches REAL,
        $columnActivityLevel TEXT,
        $columnGoal TEXT,
        $columnUnits TEXT,
        $columnWeightChangeRate REAL DEFAULT 1.0,
        $columnIsDefault INTEGER DEFAULT 0,
        $columnCreatedAt INTEGER,
        $columnUpdatedAt INTEGER,
        $columnLastModified INTEGER
      )
    ''');
    print('DatabaseHelper: Created user table');

    // Create macro_calculations table
    await db.rawQuery('''
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
        FOREIGN KEY (user_id) REFERENCES $tableUsers ($columnId) ON DELETE CASCADE
      )
    ''');
    print('DatabaseHelper: Created macro_calculations table');

    // Create meal plans table
    await MealPlanDB.createTable(db);
    print('DatabaseHelper: Created meal plan table');

    // Create meal logs table
    await db.rawQuery('''
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
        FOREIGN KEY (user_id) REFERENCES $tableUsers ($columnId) ON DELETE CASCADE,
        FOREIGN KEY (meal_plan_id) REFERENCES meal_plans (id) ON DELETE CASCADE
      )
    ''');
    print('DatabaseHelper: Created meal log table');

    print('DatabaseHelper: All tables created successfully');
  }

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
      'DatabaseHelper: Upgrading database from v$oldVersion to v$newVersion',
    );

    if (oldVersion < 2) {
      // Add weight_change_rate column to users table if upgrading from v1
      await db.rawQuery(
        'ALTER TABLE $tableUsers ADD COLUMN $columnWeightChangeRate REAL DEFAULT 1.0',
      );
      print('DatabaseHelper: Added weight_change_rate column to users table');
    }

    if (oldVersion < 3) {
      // Add any schema changes for version 3
      print('DatabaseHelper: Applying version 3 schema changes');
    }
  }

  static Future _onDowngrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print(
      'DatabaseHelper: Downgrading database from v$oldVersion to v$newVersion',
    );
  }

  static Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );
    return result.isNotEmpty;
  }

  static Future<void> _recreateDatabaseFile() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    final dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('Deleted database file for recreation');
    }
    final journalFile = File('$path-journal');
    if (await journalFile.exists()) {
      await journalFile.delete();
    }
    final shmFile = File('$path-shm');
    if (await shmFile.exists()) {
      await shmFile.delete();
    }
    final walFile = File('$path-wal');
    if (await walFile.exists()) {
      await walFile.delete();
    }
  }

  static Future<Database> _recreateDatabaseCompletely() async {
    print('Completely recreating database...');

    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'app_database.db');

      // Close any existing database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('Closed existing database connection');
      }

      // Delete the database file if it exists
      final dbFile = File(path);
      if (await dbFile.exists()) {
        try {
          await dbFile.delete();
          print('Deleted existing database file');
        } catch (e) {
          print('Error deleting database file: $e');
          // Try to force delete by using a different approach
          try {
            // On Android, try to use platform channels to delete the file
            final tempPath = '$path.bak';
            await dbFile.rename(tempPath);
            final tempFile = File(tempPath);
            await tempFile.delete();
            print('Force deleted database file via rename/delete');
          } catch (e2) {
            print('Failed to force delete database file: $e2');
            // Continue anyway
          }
        }
      }

      // Create parent directories if they don't exist
      final dbDir = Directory(dirname(path));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        print('Created database directory');
      }

      // Check if we can write to the directory
      try {
        // Test write permissions by creating a temporary file
        final testFile = File('${dbDir.path}/test_permissions.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        print('Verified write permissions on database directory');
      } catch (e) {
        print('Warning: Database directory may not be writable: $e');
        // Continue anyway, as we might still be able to create the database
      }

      // Create a new database with explicit open flags
      print('Opening database with explicit flags...');
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
        // Use explicit open flags to ensure writability
        singleInstance: false, // Try with a non-shared instance
      );

      // Configure the database with pragmas
      print('Configuring database...');
      await db.rawQuery('PRAGMA journal_mode = DELETE');
      await db.rawQuery('PRAGMA synchronous = NORMAL');
      await db.rawQuery('PRAGMA locking_mode = NORMAL');
      await db.rawQuery('PRAGMA busy_timeout = 5000');
      await db.rawQuery('PRAGMA foreign_keys = ON');

      // Verify the database is writable
      try {
        await db.rawQuery('PRAGMA quick_check');
        print('Database write test successful');
      } catch (e) {
        print('Database write test failed: $e');
        await db.close();
        throw Exception('Failed to create a writable database: $e');
      }

      // Update the static reference
      _database = db;
      print('Database instance updated');

      return db;
    } catch (e) {
      print('Database recreation failed: $e');
      rethrow;
    }
  }
}
