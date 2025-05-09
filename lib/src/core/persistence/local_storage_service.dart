// lib/src/core/persistence/local_storage_service.dart
import 'dart:convert';
import 'dart:core';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite for Database type and ConflictAlgorithm
import 'database_helper.dart'; // Import DatabaseHelper for table/column names

/// LocalStorageService acts as a bridge between FirestoreSyncService and local storage (SQLite)
/// It handles all local storage operations and sync queue persistence
class LocalStorageService {
  final UserDB userDB; // Add UserDB instance

  // Keys for storing data in the settings table
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncTimeKey = 'last_sync_time';

  // Update constructor to accept only UserDB
  LocalStorageService(this.userDB);

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

        if (errorMsg.contains('read-only') ||
            errorMsg.contains('database_closed') ||
            errorMsg.contains('database is closed')) {
          try {
            // Get a fresh database instance with recovery if needed
            // Use force recreation on the last retry attempt

            await DatabaseHelper.verifyDatabaseWritable();
            retryCount++;

            // Small delay before retry to allow system to stabilize
            await Future.delayed(Duration(milliseconds: 300));
            continue; // Retry the operation with the recovered database
          } catch (recoveryError) {
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

  // User Info methods (These already use UserDB static methods, no change needed here)
  Future<List<UserInfo>?> getSavedUserInfos(String userId) async {
    try {
      // Use UserDB instance method
      return await userDB.getAllUsers(firebaseUserId: userId);
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
      return null;
    }
  }

  Future<void> saveUserInfos(String userId, List<UserInfo> userInfos) async {
    // No change needed in implementation, but added error check
    try {
      for (var userInfo in userInfos) {
        await saveUserInfo(userId, userInfo);
      }
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<void> saveUserInfo(String userId, UserInfo userInfo) async {
    // No change needed in implementation, but added error check
    try {
      final userInfoWithId =
          userInfo.id == null
              ? userInfo.copyWith(
                // Consider generating a local ID if needed, e.g., using uuid
                // For now, let's assume UserDB handles ID generation or expects one
              ) // Placeholder if ID needs generation
              : userInfo;

      // Use UserDB instance method (assuming insertUser or updateUser)
      // Check if user exists to decide between insert and update
      final existingUser = await userDB.getUserById(
        userInfoWithId.id ?? '',
      ); // Need to handle potential null ID
      if (existingUser != null) {
        await userDB.updateUser(userInfoWithId, userId);
      } else {
        // Assuming insertUser exists and handles ID if null
        // Remove firebaseUserId parameter as it's no longer defined in UserDB.insertUser
        await userDB.insertUser(userInfoWithId, userId);
      }
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<void> deleteUserInfo(String userId, String id) async {
    try {
      final rowsDeleted = await userDB.deleteUser(id);
      if (rowsDeleted > 0) ;
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<void> setDefaultUserInfo(String userId, String id) async {
    // No change needed in implementation, but added error check
    try {
      final userInfos = await getSavedUserInfos(userId);
      if (userInfos == null || userInfos.isEmpty) return;

      for (var userInfo in userInfos) {
        final updatedUserInfo = userInfo.copyWith(
          isDefault: userInfo.id == id,
          lastModified: DateTime.now(),
        );
        // saveUserInfo will now rethrow the read-only error if it occurs
        await saveUserInfo(userId, updatedUserInfo);
      }
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<UserInfo?> getDefaultUserInfo(String userId) async {
    // No change needed
    try {
      final userInfos = await getSavedUserInfos(userId);
      if (userInfos == null || userInfos.isEmpty) return null;

      final defaultUserInfo = userInfos.firstWhere(
        (userInfo) => userInfo.isDefault,
        orElse: () => userInfos.first,
      );

      return defaultUserInfo;
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
      return null;
    }
  }

  Future<void> saveUser(UserInfo user) async {
    // No change needed in implementation, but added error check
    try {
      final userId = user.id ?? ''; // Ensure userId is available
      await saveUserInfo(userId, user);
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<bool> updateUserInfo(UserInfo userInfo, String firebaseUserId) async {
    // No change needed in implementation, but added error check
    try {
      // UserDB methods already log hashcode and errors
      if (userInfo.id == null) {
        await userDB.insertUser(userInfo, firebaseUserId);
        return true;
      }
      final success = await userDB.updateUser(userInfo, firebaseUserId);
      // ... logging ...
      return success;
    } catch (e) {
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
      return false;
    }
  }

  // Sync queue methods - REWRITTEN to use DatabaseHelper.getInstance()
  Future<List<Map<String, dynamic>>?> getSyncQueue() async {
    return await executeWithRecovery((db) async {
      try {
        final List<Map<String, dynamic>> maps = await db.query(
          DatabaseHelper.tableSettings,
          columns: [DatabaseHelper.columnValue],
          where: '${DatabaseHelper.columnKey} = ?',
          whereArgs: [_syncQueueKey],
        );

        if (maps.isNotEmpty) {
          final queueJson = maps.first[DatabaseHelper.columnValue] as String?;
          if (queueJson == null) return [];
          final List<dynamic> decodedList = jsonDecode(queueJson);
          return decodedList.cast<Map<String, dynamic>>();
        } else {
          return [];
        }
      } catch (e) {
        if (e.toString().contains('read-only')) {
          rethrow; // Propagate the specific error
        }
        return []; // Return empty list on error
      }
    });
  }

  Future<void> setSyncQueue(List<Map<String, dynamic>> queue) async {
    await executeWithRecovery((db) async {
      print('[DIAG] setSyncQueue starting with DB hash: ${db.hashCode}');
      try {
        final queueJson = jsonEncode(queue);
        await db.insert(
          DatabaseHelper.tableSettings,
          {
            DatabaseHelper.columnKey: _syncQueueKey,
            DatabaseHelper.columnValue: queueJson,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        if (e.toString().contains('read-only')) {
          rethrow; // Propagate the specific error
        }
      }
    });
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await executeWithRecovery((db) async {
      try {
        final timeString = time.millisecondsSinceEpoch.toString();
        await db.insert(
          DatabaseHelper.tableSettings,
          {
            DatabaseHelper.columnKey: _lastSyncTimeKey,
            DatabaseHelper.columnValue: timeString,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        if (e.toString().contains('read-only')) {
          rethrow; // Propagate the specific error
        }
        // No print or debug output
      }
    });
  }

  Future<DateTime?> getLastSyncTime() async {
    return await executeWithRecovery((db) async {
      try {
        final List<Map<String, dynamic>> maps = await db.query(
          DatabaseHelper.tableSettings,
          columns: [DatabaseHelper.columnValue],
          where: '${DatabaseHelper.columnKey} = ?',
          whereArgs: [_lastSyncTimeKey],
        );
        if (maps.isEmpty) return null;
        final timeString = maps.first[DatabaseHelper.columnValue] as String?;
        if (timeString == null) return null;
        final timestamp = int.parse(timeString);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) {
        if (e.toString().contains('read-only')) {
          rethrow; // Propagate the specific error
        }
        return null; // Return null on error
      }
    });
  }
}
