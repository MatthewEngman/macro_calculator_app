// lib/src/core/persistence/local_storage_service.dart
import 'dart:convert';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite for Database type and ConflictAlgorithm
import 'database_helper.dart'; // Import DatabaseHelper for table/column names

/// LocalStorageService acts as a bridge between FirestoreSyncService and local storage (SQLite)
/// It handles all local storage operations and sync queue persistence
class LocalStorageService {
  // Change to accept Database directly
  final Database database;
  final UserDB userDB; // Add UserDB instance

  // Keys for storing data in the settings table
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncTimeKey = 'last_sync_time';

  // Update constructor to accept UserDB
  LocalStorageService(this.userDB, this.database) {
    print('[DIAG] LocalStorageService constructed');
    try {
      print('[DIAG] userDB: $userDB');
      print('[DIAG] Underlying DB hash: ${database.hashCode}');
      print('[DIAG] Underlying DB path: ${database.path}');
    } catch (e) {
      print('[DIAG] Could not get database path: $e');
    }
  }

  // User Info methods (These already use UserDB static methods, no change needed here)
  Future<List<UserInfo>?> getSavedUserInfos(String userId) async {
    try {
      // Use UserDB instance method
      return await userDB.getAllUsers(firebaseUserId: userId);
    } catch (e) {
      print('Error getting saved user infos: $e');
      // Rethrow the error to be handled by the caller if needed
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
      print('Error saving user infos: $e');
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<void> saveUserInfo(String userId, UserInfo userInfo) async {
    // No change needed in implementation, but added error check
    print('[DIAG] saveUserInfo using DB hash: ${database.hashCode}');
    try {
      print('[DIAG] DB path: ${database.path}');
    } catch (_) {}
    // ...rest of your method...
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
      print('Error saving user info: $e');
      // Rethrow the error so callers (like FirestoreSyncService) are aware
      rethrow;
    }
  }

  Future<void> deleteUserInfo(String userId, String id) async {
    print('[DIAG] deleteUserInfo using DB hash: ${database.hashCode}');
    try {
      print('[DIAG] DB path: ${database.path}');
    } catch (_) {}
    // No change needed
    try {
      final rowsDeleted = await userDB.deleteUser(id);
      if (rowsDeleted > 0) {
        print('LocalStorageService: Successfully deleted user with ID: $id');
      } else {
        print('LocalStorageService: No user found with ID: $id to delete');
      }
    } catch (e) {
      print('Error deleting user info: $e');
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
      print('Error setting default user info: $e');
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
      print('Error getting default user info: $e');
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
      print('Error saving user: $e');
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
        print(
          'LocalStorageService: Cannot update user without ID, inserting instead',
        );
        await userDB.insertUser(userInfo, firebaseUserId);
        return true;
      }
      final success = await userDB.updateUser(userInfo, firebaseUserId);
      // ... logging ...
      return success;
    } catch (e) {
      print('LocalStorageService: Error updating user: $e');
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
      return false;
    }
  }

  // Sync queue methods - REWRITTEN to use Database directly
  Future<List<Map<String, dynamic>>?> getSyncQueue() async {
    print('[DIAG] getSyncQueue using DB hash: ${database.hashCode}');
    try {
      print('[DIAG] DB path: ${database.path}');
    } catch (_) {}
    try {
      final List<Map<String, dynamic>> maps = await database.query(
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
      print('Error getting sync queue directly from DB: $e');
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
      return []; // Return empty list on error
    }
  }

  Future<void> setSyncQueue(List<Map<String, dynamic>> queue) async {
    try {
      final queueJson = jsonEncode(queue);
      await database.insert(DatabaseHelper.tableSettings, {
        DatabaseHelper.columnKey: _syncQueueKey,
        DatabaseHelper.columnValue: queueJson,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error setting sync queue directly in DB: $e');
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<void> setLastSyncTime(DateTime time) async {
    try {
      final timeString = time.millisecondsSinceEpoch.toString();
      await database.insert(DatabaseHelper.tableSettings, {
        DatabaseHelper.columnKey: _lastSyncTimeKey,
        DatabaseHelper.columnValue: timeString,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print('Error setting last sync time directly in DB: $e');
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        DatabaseHelper.tableSettings,
        columns: [DatabaseHelper.columnValue],
        where: '${DatabaseHelper.columnKey} = ?',
        whereArgs: [_lastSyncTimeKey],
      );
      if (maps.isNotEmpty) {
        final timeString = maps.first[DatabaseHelper.columnValue] as String?;
        if (timeString == null) return null;
        final timestamp = int.parse(timeString);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting last sync time directly from DB: $e');
      if (e.toString().contains('read-only')) {
        rethrow; // Propagate the specific error
      }
      return null;
    }
  }
}
