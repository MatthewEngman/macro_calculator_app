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

  static Database? _database;

  static void setDatabase(Database db) {
    _database = db;
    print('DatabaseHelper: Database instance set manually');
  }

  static Database get database {
    if (_database == null) {
      print('FATAL: DatabaseHelper database instance is null!');
      throw StateError(
        'DatabaseHelper database instance has not been set. Ensure DatabaseHelper.setDatabase() is called during initialization.',
      );
    }
    return _database!;
  }

  static Future<Database> initDatabase() async {
    const databaseName = "app_database.db";
    const databaseVersion = 3;

    try {
      final dbPath = await getDatabasesPath();
      final dbDirectory = Directory(dbPath);
      if (!await dbDirectory.exists()) {
        await dbDirectory.create(recursive: true);
      }

      String path = join(dbPath, databaseName);

      final file = File(path);
      if (await file.exists()) {
        try {
          final raf = await file.open(mode: FileMode.append);
          await raf.close();
        } catch (e) {
          print('Database file exists but is not writable: $e');
          final journalFile = File('$path-journal');
          if (await journalFile.exists()) {
            await journalFile.delete();
            print('Deleted journal file.');
          }
          final shmFile = File('$path-shm');
          if (await shmFile.exists()) {
            await shmFile.delete();
            print('Deleted shm file.');
          }
          final walFile = File('$path-wal');
          if (await walFile.exists()) {
            await walFile.delete();
            print('Deleted wal file.');
          }
          await file.delete();
          print('Deleted potentially read-only database file, will recreate');
        }
      }

      final db = await openDatabase(
        path,
        version: databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        readOnly: false,
        singleInstance: true,
      );

      print('Database successfully initialized in write mode by initDatabase');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      final db = await openDatabase(
        ':memory:',
        version: databaseVersion,
        onCreate: _onCreate,
        readOnly: false,
      );
      print('Using in-memory database as fallback');
      return db;
    }
  }

  static Future _onConfigure(Database db) async {
    print('DatabaseHelper: Configuring database...');
    try {
      await db.execute('PRAGMA journal_mode=WAL');
      await db.execute('PRAGMA foreign_keys=ON');
      print('DatabaseHelper: WAL mode and foreign keys enabled.');
    } catch (e, stack) {
      print('DatabaseHelper: Error configuring database (PRAGMAs): $e');
      print('DatabaseHelper: Stack trace: $stack');
      // Decide if this is fatal. WAL is nice but not essential.
      // Foreign keys might be more critical depending on your schema.
      // For now, we let it continue, but log the error.
    }
  }

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

  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
      'DatabaseHelper: Upgrading database from version $oldVersion to $newVersion',
    );
    try {
      if (oldVersion < 2) {
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

  static Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );
    return result.isNotEmpty;
  }
}
