import 'package:sqflite/sqflite.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';

/// Database helper class for User operations
class UserDB {
  static const String tableName = 'users';
  static const String columnIsDefault = 'is_default';

  final Database database;

  UserDB({required this.database});

  /// Creates the users table in the database
  static Future<void> createTable(Database db) async {
    try {
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
          $columnIsDefault INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_modified INTEGER,
          weight_change_rate REAL DEFAULT 1.0
        )
      ''');
    } catch (e) {
      print('UserDB: Error creating table: $e');
      rethrow;
    }
  }

  /// Inserts a new user into the database
  Future<String> insertUser(UserInfo user, String firebaseUserId) async {
    print('Database HashCode in UserDB (insertUser): ${database.hashCode}');

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

    try {
      await database.insert(
        tableName,
        userData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('UserDB: Successfully inserted user with ID: $id');
      return id;
    } catch (e) {
      print('UserDB: Error inserting user: $e');
      rethrow;
    }
  }

  /// Updates an existing user in the database with timestamp-based conflict resolution
  Future<bool> updateUser(UserInfo user, String firebaseUserId) async {
    print('Database HashCode in UserDB (updateUser): ${database.hashCode}');

    if (user.id == null) {
      // Instead of throwing an error, insert a new user with a generated ID
      print('UserDB: Cannot update a user without an ID, inserting instead');
      await insertUser(user, firebaseUserId);
      return true;
    }

    // First check if the record exists and get its current lastModified value
    final existingUser = await getUserById(user.id!);
    if (existingUser == null) {
      // User doesn't exist, insert it instead
      await insertUser(user, firebaseUserId);
      return true;
    }

    // Implement timestamp-based conflict resolution
    final existingLastModified =
        existingUser.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
    final newLastModified = user.lastModified ?? DateTime.now();

    if (existingLastModified.isAfter(newLastModified)) {
      // Existing record is newer, don't update
      print('UserDB: Update skipped for ${user.id}. Existing record is newer.');
      return false;
    }

    final userData = user.toJson();
    userData['firebase_user_id'] = firebaseUserId;
    userData['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    userData['last_modified'] = newLastModified.millisecondsSinceEpoch;
    userData['is_default'] = user.isDefault ? 1 : 0;

    int rowsAffected = 0;
    await database.transaction((txn) async {
      rowsAffected = await txn.update(
        tableName,
        userData,
        where: 'id = ?',
        whereArgs: [user.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    if (rowsAffected > 0) {
      print('UserDB: Successfully updated user with ID: ${user.id}');
      return true;
    } else {
      return false;
    }
  }

  /// Deletes a user from the database
  Future<int> deleteUser(String id) async {
    return await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Gets a user by ID
  Future<UserInfo?> getUserById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
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
    } else {
      userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserInfo.fromJson(userData);
  }

  /// Gets a user by Firebase user ID (assuming one primary profile per Firebase ID for sync)
  Future<UserInfo?> getUserByFirebaseId(String firebaseUserId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'firebase_user_id = ?',
      whereArgs: [firebaseUserId],
      limit: 1, // Expecting one primary local profile linked for sync
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
    } else {
      userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserInfo.fromJson(userData);
  }

  /// Gets all users for a specific Firebase user
  Future<List<UserInfo>> getAllUsers({required String firebaseUserId}) async {
    final List<Map<String, dynamic>> maps = await database.query(
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
      } else {
        userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(0);
      }

      return UserInfo.fromJson(userData);
    });
  }

  /// Sets a user as the default user
  Future<void> setDefaultUser(
    String id, {
    required String firebaseUserId,
  }) async {
    await database.transaction((txn) async {
      // First, unset all default users for this Firebase user
      await txn.update(
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
      await txn.update(
        tableName,
        {
          'is_default': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'last_modified': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Gets the default user for a specific Firebase user
  Future<UserInfo?> getDefaultUser({required String firebaseUserId}) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'firebase_user_id = ? AND is_default = 1',
      whereArgs: [firebaseUserId],
    );

    if (maps.isNotEmpty) {
      final userData = maps.first;
      userData['isDefault'] = userData['is_default'] == 1;

      if (userData['last_modified'] != null) {
        userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(
          userData['last_modified'],
        );
      } else {
        userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(0);
      }

      return UserInfo.fromJson(userData);
    } else {
      // If no specific default is set, return the most recently modified user
      final allUsers = await getAllUsers(firebaseUserId: firebaseUserId);
      if (allUsers.isEmpty) return null;
      allUsers.sort((a, b) {
        final timeA = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA); // Sort descending by time
      });
      return allUsers.first;
    }
  }
}
