import 'package:sqflite/sqflite.dart';
import 'package:macro_masher/src/core/persistence/database_helper.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';

/// Database helper class for User operations
class UserDB {
  static const String tableName = 'users';

  /// Creates the users table in the database
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        firebase_user_id TEXT NOT NULL,
        weight REAL,
        age INTEGER,
        sex TEXT NOT NULL,
        activity_level TEXT NOT NULL,
        goal TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Inserts a new user into the database
  static Future<int> insertUser(UserInfo user, String firebaseUserId) async {
    final db = await DatabaseHelper.instance.database;

    final userData = user.toJson();
    userData['firebase_user_id'] = firebaseUserId;
    userData['created_at'] = DateTime.now().millisecondsSinceEpoch;
    userData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    return await db.insert(tableName, userData);
  }

  /// Updates an existing user in the database
  static Future<int> updateUser(UserInfo user) async {
    final db = await DatabaseHelper.instance.database;

    final userData = user.toJson();
    userData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    return await db.update(
      tableName,
      userData,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Deletes a user from the database
  static Future<int> deleteUser(String id) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Gets a user by ID
  static Future<UserInfo?> getUserById(String id) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserInfo.fromJson(maps.first);
  }

  /// Gets all users for a specific Firebase user
  static Future<List<UserInfo>> getAllUsers({
    required String firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'firebase_user_id = ?',
      whereArgs: [firebaseUserId],
    );

    return List.generate(maps.length, (i) {
      return UserInfo.fromJson(maps[i]);
    });
  }

  /// Sets a user as the default user
  static Future<void> setDefaultUser(
    String id, {
    required String firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // First, unset all default users for this Firebase user
    await db.update(
      tableName,
      {'is_default': 0},
      where: 'firebase_user_id = ?',
      whereArgs: [firebaseUserId],
    );

    // Then set the specified user as default
    await db.update(
      tableName,
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Gets the default user for a specific Firebase user
  static Future<UserInfo?> getDefaultUser({
    required String firebaseUserId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'firebase_user_id = ? AND is_default = 1',
      whereArgs: [firebaseUserId],
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserInfo.fromJson(maps.first);
  }
}
