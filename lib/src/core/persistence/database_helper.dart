import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/meal_plan/data/meal_plan_db.dart';

class DatabaseHelper {
  static const _databaseName = "app_database.db";
  static const _databaseVersion = 1;

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

    // Create meal_plans table
    await MealPlanDB.createTable(db);
  }
}
