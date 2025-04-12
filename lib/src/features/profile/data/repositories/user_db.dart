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
        feet INTEGER,
        inches INTEGER,
        age INTEGER,
        sex TEXT NOT NULL,
        activity_level INTEGER NOT NULL,
        goal INTEGER NOT NULL,
        units INTEGER NOT NULL,
        name TEXT,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_modified INTEGER
      )
    ''');
  }

  /// Inserts a new user into the database
  static Future<String> insertUser(UserInfo user, String firebaseUserId) async {
    final db = await DatabaseHelper.instance.database;

    final id = user.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final lastModified =
        user.lastModified?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;

    final userData = user.toJson();
    userData['id'] = id;
    userData['firebase_user_id'] = firebaseUserId;
    userData['created_at'] = DateTime.now().millisecondsSinceEpoch;
    userData['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    userData['last_modified'] = lastModified;
    userData['is_default'] = user.isDefault ? 1 : 0;

    await db.insert(
      tableName,
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  /// Updates an existing user in the database with timestamp-based conflict resolution
  static Future<bool> updateUser(UserInfo user, String firebaseUserId) async {
    final db = await DatabaseHelper.instance.database;

    if (user.id == null) {
      throw ArgumentError('Cannot update a user without an ID');
    }

    // First check if the record exists and get its current lastModified value
    final existingUser = await getUserById(user.id!);
    if (existingUser == null) {
      // User doesn't exist, insert it instead
      await insertUser(user, firebaseUserId);
      return true;
    }

    // If the existing record has a newer lastModified timestamp, don't update
    final existingLastModified = existingUser.lastModified ?? DateTime(1970);
    final newLastModified = user.lastModified ?? DateTime.now();

    if (existingLastModified.isAfter(newLastModified)) {
      // Existing record is newer, don't update
      return false;
    }

    final userData = user.toJson();
    userData['firebase_user_id'] = firebaseUserId;
    userData['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    userData['last_modified'] = DateTime.now().millisecondsSinceEpoch;
    userData['is_default'] = user.isDefault ? 1 : 0;

    final rowsAffected = await db.update(
      tableName,
      userData,
      where: 'id = ?',
      whereArgs: [user.id],
    );

    return rowsAffected > 0;
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

    final userData = maps.first;
    userData['isDefault'] = userData['is_default'] == 1;

    if (userData['last_modified'] != null) {
      userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(
        userData['last_modified'],
      );
    }

    return UserInfo.fromJson(userData);
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
      final userData = maps[i];
      userData['isDefault'] = userData['is_default'] == 1;

      if (userData['last_modified'] != null) {
        userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(
          userData['last_modified'],
        );
      }

      return UserInfo.fromJson(userData);
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
      {
        'is_default': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'last_modified': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'firebase_user_id = ?',
      whereArgs: [firebaseUserId],
    );

    // Then set the specified user as default
    await db.update(
      tableName,
      {
        'is_default': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'last_modified': DateTime.now().millisecondsSinceEpoch,
      },
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

    final userData = maps.first;
    userData['isDefault'] = userData['is_default'] == 1;

    if (userData['last_modified'] != null) {
      userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(
        userData['last_modified'],
      );
    }

    return UserInfo.fromJson(userData);
  }
}
