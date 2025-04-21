import 'package:sqflite/sqflite.dart';
import 'database_helper.dart'; // Import the helper

class PersistenceService {
  // Remove direct database reference and use dynamic retrieval instead
  bool _initialized = false;

  // Constructor no longer needs to accept a database
  PersistenceService();

  // Get the current database instance dynamically
  Future<Database> _getDatabase() async {
    return await DatabaseHelper.getInstance();
  }

  // Initialize method to ensure settings table exists
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('PersistenceService: Checking if settings table exists...');
      final db = await _getDatabase();
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseHelper.tableSettings}'",
      );
      print('PersistenceService: Table query result: $tables');

      if (tables.isEmpty) {
        print('PersistenceService: Creating settings table...');
        await db.execute('''
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
    final db = await _getDatabase();

    await db.insert(
      DatabaseHelper.tableSettings,
      {DatabaseHelper.columnKey: key, DatabaseHelper.columnValue: value},
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Use replace for key-value store behavior
    );
  }

  // Get data using SELECT WHERE
  Future<String?> getData(String key) async {
    await initialize();
    final db = await _getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
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
