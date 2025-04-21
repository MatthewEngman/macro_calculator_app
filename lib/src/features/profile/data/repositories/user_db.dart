import 'package:sqflite/sqflite.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:macro_masher/src/core/persistence/database_helper.dart';

/// Database helper class for User operations
class UserDB {
  static const String tableName = 'users';
  static const String columnIsDefault = 'is_default';

  UserDB();

  /// Generic method to execute database operations with automatic recovery
  /// This handles both read-only errors and database closure errors
  Future<T> executeWithRecovery<T>(
    Future<T> Function(Database db) operation,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Always get the latest database instance
        final db = await DatabaseHelper.getInstance();
        return await operation(db);
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        print('Database error in executeWithRecovery: $e');

        if (errorMsg.contains('read-only') ||
            errorMsg.contains('database_closed') ||
            errorMsg.contains('database is closed')) {
          print(
            'Attempting database recovery, retry ${retryCount + 1}/$maxRetries',
          );

          try {
            // Get a fresh database instance with recovery if needed
            await DatabaseHelper.verifyDatabaseWritable();
            retryCount++;

            // Small delay before retry to allow system to stabilize
            await Future.delayed(Duration(milliseconds: 200));
            continue; // Retry the operation with the recovered database
          } catch (recoveryError) {
            print('Recovery attempt failed: $recoveryError');
            if (retryCount >= maxRetries - 1) {
              throw Exception(
                'Database recovery failed after $maxRetries attempts: $e',
              );
            }
          }
        } else {
          // For other errors, just rethrow
          rethrow;
        }
      }
      retryCount++;
    }

    throw Exception('Database operation failed after $maxRetries attempts');
  }

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
    try {
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

      final db = await DatabaseHelper.getInstance();
      await executeWithRecovery((db) async {
        print('[DIAG] Inserting user with DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');

        await db.insert(
          tableName,
          userData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        print(
          '[DIAG] Insert completed successfully with DB hash: ${db.hashCode}',
        );
        return true;
      });

      print('UserDB: Successfully inserted user with ID: $id');
      return id;
    } catch (e) {
      print('UserDB: Error inserting user: $e');
      rethrow;
    }
  }

  /// Updates an existing user in the database with timestamp-based conflict resolution
  Future<bool> updateUser(UserInfo user, String firebaseUserId) async {
    try {
      if (user.id == null) {
        // Instead of throwing an error, insert a new user with a generated ID
        final newId = await insertUser(user, firebaseUserId);
        print('UserDB: Created new user with ID: $newId instead of updating');
        return true;
      }

      // Get the existing user to check timestamps
      final existingUser = await getUserById(user.id!);
      if (existingUser == null) {
        print('UserDB: User ${user.id} not found, inserting instead');
        await insertUser(user, firebaseUserId);
        return true;
      }

      // Check if the existing user has a newer timestamp
      final existingLastModified =
          existingUser.lastModified?.millisecondsSinceEpoch ?? 0;
      final newLastModified =
          user.lastModified?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;

      // If the existing user has a newer timestamp, don't update
      if (existingLastModified > newLastModified) {
        print(
          'UserDB: Skipping update for user ${user.id} due to conflict resolution',
        );
        return false;
      }

      final userData = user.toJson();
      userData['firebase_user_id'] = firebaseUserId;
      userData['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      userData['last_modified'] = DateTime.now().millisecondsSinceEpoch;
      userData['is_default'] = user.isDefault ? 1 : 0;

      int rowsAffected = 0;

      final db = await DatabaseHelper.getInstance();
      return await executeWithRecovery((db) async {
        print('[DIAG] Updating user with DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');

        await db.transaction((txn) async {
          rowsAffected = await txn.update(
            tableName,
            userData,
            where: 'id = ?',
            whereArgs: [user.id],
          );
        });

        print(
          '[DIAG] Update completed successfully with DB hash: ${db.hashCode}',
        );

        if (rowsAffected > 0) {
          print('UserDB: Successfully updated user with ID: ${user.id}');
        }
        return rowsAffected > 0;
      });
    } catch (e) {
      print('UserDB: Error updating user: $e');
      rethrow;
    }
  }

  /// Deletes a user from the database
  Future<int> deleteUser(String id) async {
    return await executeWithRecovery((db) async {
      return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Gets a user by ID
  Future<UserInfo?> getUserById(String id) async {
    return await executeWithRecovery((db) async {
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
      } else {
        userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(0);
      }

      return UserInfo.fromJson(userData);
    });
  }

  /// Gets a user by Firebase user ID (assuming one primary profile per Firebase ID for sync)
  Future<UserInfo?> getUserByFirebaseId(String firebaseUserId) async {
    return await executeWithRecovery((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
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
    });
  }

  /// Gets all users for a specific Firebase user
  Future<List<UserInfo>> getAllUsers({required String firebaseUserId}) async {
    return await executeWithRecovery((db) async {
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
        } else {
          userData['lastModified'] = DateTime.fromMillisecondsSinceEpoch(0);
        }

        return UserInfo.fromJson(userData);
      });
    });
  }

  /// Sets a user as the default user
  Future<void> setDefaultUser(
    String id, {
    required String firebaseUserId,
  }) async {
    try {
      final db = await DatabaseHelper.getInstance();
      return await executeWithRecovery((db) async {
        print('[DIAG] Setting default user with DB hash: ${db.hashCode}');
        print('[DIAG] DB path: ${db.path}');

        await db.transaction((txn) async {
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

        print(
          '[DIAG] Default user set successfully with DB hash: ${db.hashCode}',
        );
        return;
      });
    } catch (e) {
      print('UserDB: Error setting default user: $e');
      rethrow;
    }
  }

  /// Gets the default user for a specific Firebase user
  Future<UserInfo?> getDefaultUser({required String firebaseUserId}) async {
    return await executeWithRecovery((db) async {
      final List<Map<String, dynamic>> maps = await db.query(
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
          final timeA =
              a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB =
              b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA); // Sort descending by time
        });
        return allUsers.first;
      }
    });
  }
}
