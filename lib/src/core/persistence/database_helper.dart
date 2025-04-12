import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/meal_plan/data/meal_plan_db.dart';
import '../../features/calculator/data/repositories/macro_calculation_db.dart';
import '../../features/profile/data/repositories/user_db.dart';
import '../../features/meal_plan/data/meal_log_db.dart';

class DatabaseHelper {
  static const _databaseName = "app_database.db";
  static const _databaseVersion = 2; // Increased version for schema update

  static const tableSettings = 'settings';
  static const columnKey = 'key';
  static const columnValue = 'value';

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the db the first time it is accessed.
    _database = await _initDatabase();
    return _database!;
  }

  // Open the database (and create it if it doesn't exist).
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // SQL code to create the database table.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableSettings (
            $columnKey TEXT PRIMARY KEY,
            $columnValue TEXT NOT NULL
          )
          ''');

    // Create tables
    await MealPlanDB.createTable(db);
    await UserDB.createTable(db);
    await MacroCalculationDB.createTable(db);
    await MealLogDB.createTable(db);
  }

  // Handle database upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables if upgrading from version 1
      if (!await _tableExists(db, UserDB.tableName)) {
        await UserDB.createTable(db);
      }
      if (!await _tableExists(db, MacroCalculationDB.tableName)) {
        await MacroCalculationDB.createTable(db);
      }
      if (!await _tableExists(db, MealLogDB.tableName)) {
        await MealLogDB.createTable(db);
      }
    }
  }

  // Helper method to check if a table exists
  Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
    );
    return result.isNotEmpty;
  }
}
