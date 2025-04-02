import 'package:sqflite/sqflite.dart';
import 'database_helper.dart'; // Import the helper

class PersistenceService {
  final Database database; // Changed from SharedPreferences

  PersistenceService(this.database); // Constructor accepts Database

  // Save data using INSERT OR REPLACE
  Future<void> saveData(String key, String value) async {
    await database.insert(
      DatabaseHelper.tableSettings,
      {DatabaseHelper.columnKey: key, DatabaseHelper.columnValue: value},
      conflictAlgorithm: ConflictAlgorithm.replace, // Use replace for key-value store behavior
    );
  }

  // Get data using SELECT WHERE
  Future<String?> getData(String key) async {
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