// lib/src/core/persistence/local_storage_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth_lib;
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';
import 'persistence_service.dart';

/// LocalStorageService acts as a bridge between FirestoreSyncService and local storage (SQLite)
/// It handles all local storage operations and sync queue persistence
class LocalStorageService {
  final PersistenceService _persistenceService;

  // Keys for storing data
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncTimeKey = 'last_sync_time';

  LocalStorageService(this._persistenceService);

  // User Info methods
  Future<List<UserInfo>?> getSavedUserInfos(String userId) async {
    try {
      // Use UserDB.getAllUsers with the correct named parameter
      return await UserDB.getAllUsers(firebaseUserId: userId);
    } catch (e) {
      print('Error getting saved user infos: $e');
      return null;
    }
  }

  Future<void> saveUserInfos(String userId, List<UserInfo> userInfos) async {
    try {
      // Save each user info to SQLite
      for (var userInfo in userInfos) {
        await saveUserInfo(userId, userInfo);
      }
    } catch (e) {
      print('Error saving user infos: $e');
    }
  }

  Future<void> saveUserInfo(String userId, UserInfo userInfo) async {
    try {
      // Ensure user has an ID before saving
      final userInfoWithId =
          userInfo.id == null
              ? userInfo.copyWith(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              )
              : userInfo;

      // Use UserDB to save user info to SQLite with timestamp-based conflict resolution
      final userInfoWithTimestamp = userInfoWithId.copyWith(
        lastModified: userInfoWithId.lastModified ?? DateTime.now(),
      );

      // Choose between insert and update based on whether the user has an ID
      if (userInfoWithTimestamp.id == null) {
        print('LocalStorageService: Generated new ID for user');
        await UserDB.insertUser(userInfoWithTimestamp, userId);
      } else {
        await UserDB.updateUser(userInfoWithTimestamp, userId);
      }
    } catch (e) {
      print('Error saving user info: $e');
      // In production, you might want to log this error to a service
    }
  }

  Future<void> deleteUserInfo(String userId, String id) async {
    try {
      // UserDB.deleteUser returns an int (number of rows affected), not void
      final rowsDeleted = await UserDB.deleteUser(id);
      if (rowsDeleted > 0) {
        print('LocalStorageService: Successfully deleted user with ID: $id');
      } else {
        print('LocalStorageService: No user found with ID: $id to delete');
      }
    } catch (e) {
      print('Error deleting user info: $e');
    }
  }

  Future<void> setDefaultUserInfo(String userId, String id) async {
    try {
      // Get all user infos
      final userInfos = await getSavedUserInfos(userId);
      if (userInfos == null || userInfos.isEmpty) return;

      // Update isDefault flag for all user infos
      for (var userInfo in userInfos) {
        final updatedUserInfo = userInfo.copyWith(
          isDefault: userInfo.id == id,
          lastModified: DateTime.now(),
        );
        await saveUserInfo(userId, updatedUserInfo);
      }
    } catch (e) {
      print('Error setting default user info: $e');
    }
  }

  Future<UserInfo?> getDefaultUserInfo(String userId) async {
    try {
      // Get all user infos
      final userInfos = await getSavedUserInfos(userId);
      if (userInfos == null || userInfos.isEmpty) return null;

      // Find the default user info
      final defaultUserInfo = userInfos.firstWhere(
        (userInfo) => userInfo.isDefault,
        orElse: () => userInfos.first,
      );

      return defaultUserInfo;
    } catch (e) {
      print('Error getting default user info: $e');
      return null;
    }
  }

  // Method to save a user with a different signature to match the startUserDataListener method
  Future<void> saveUser(UserInfo user) async {
    try {
      // Extract userId from the user if available, otherwise use a default
      final userId = user.id ?? '';
      await saveUserInfo(userId, user);
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  /// Updates a user profile in the local database
  Future<bool> updateUserInfo(UserInfo userInfo, String firebaseUserId) async {
    try {
      if (userInfo.id == null) {
        print(
          'LocalStorageService: Cannot update user without ID, inserting instead',
        );
        await UserDB.insertUser(userInfo, firebaseUserId);
        return true;
      }

      // Use the UserDB.updateUser method which now uses the shared database instance
      final success = await UserDB.updateUser(userInfo, firebaseUserId);

      if (success) {
        print('LocalStorageService: Updated user with ID: ${userInfo.id}');
      } else {
        print(
          'LocalStorageService: Failed to update user with ID: ${userInfo.id}',
        );
      }

      return success;
    } catch (e) {
      print('LocalStorageService: Error updating user: $e');
      return false;
    }
  }

  // Sync queue methods
  Future<List<Map<String, dynamic>>?> getSyncQueue() async {
    try {
      final queueJson = await _persistenceService.getData(_syncQueueKey);
      if (queueJson == null) return [];

      final List<dynamic> decodedList = jsonDecode(queueJson);
      return decodedList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting sync queue: $e');
      return [];
    }
  }

  Future<void> setSyncQueue(List<Map<String, dynamic>> queue) async {
    try {
      final queueJson = jsonEncode(queue);
      await _persistenceService.saveData(_syncQueueKey, queueJson);
    } catch (e) {
      print('Error setting sync queue: $e');
    }
  }

  Future<void> setLastSyncTime(DateTime time) async {
    try {
      final timeString = time.millisecondsSinceEpoch.toString();
      await _persistenceService.saveData(_lastSyncTimeKey, timeString);
    } catch (e) {
      print('Error setting last sync time: $e');
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      final timeString = await _persistenceService.getData(_lastSyncTimeKey);
      if (timeString == null) return null;

      final timestamp = int.parse(timeString);
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  // Add methods for food logs, measurements, etc. as needed
  // These would follow the same pattern as the user info methods above
}
