import 'package:sqflite/sqflite.dart';
import 'database_helper.dart'; // Import the helper

class PersistenceService {
  final Database database; // Changed from SharedPreferences
  bool _initialized = false;

  PersistenceService(this.database); // Constructor accepts Database

  // Initialize method to ensure settings table exists
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('PersistenceService: Checking if settings table exists...');
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseHelper.tableSettings}'",
      );
      print('PersistenceService: Table query result: $tables');

      if (tables.isEmpty) {
        print('PersistenceService: Creating settings table...');
        await database.execute('''
        CREATE TABLE ${DatabaseHelper.tableSettings} (
          ${DatabaseHelper.columnKey} TEXT PRIMARY KEY,
          ${DatabaseHelper.columnValue} TEXT NOT NULL
        )
      ''');
        print('PersistenceService: Settings table created.');
      }

      _initialized = true;
      print('PersistenceService: Initialization complete.');
    } catch (e, stack) {
      print('Error initializing PersistenceService: $e');
      print('Stack trace: $stack');
      throw UnimplementedError('Initialize in main.dart');
    }
  }

  // Save data using INSERT OR REPLACE
  Future<void> saveData(String key, String value) async {
    await initialize();

    await database.insert(
      DatabaseHelper.tableSettings,
      {DatabaseHelper.columnKey: key, DatabaseHelper.columnValue: value},
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Use replace for key-value store behavior
    );
  }

  // Get data using SELECT WHERE
  Future<String?> getData(String key) async {
    await initialize();

    final List<Map<String, dynamic>> maps = await database.query(
      DatabaseHelper.tableSettings,
      columns: [DatabaseHelper.columnValue],
      where: '${DatabaseHelper.columnKey} = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      // Ensure the value is treated as String
      return maps.first[DatabaseHelper.columnValue] as String?;
    } else {
      return null;
    }
  }

  // Add other methods as needed (e.g., deleteData)
}
