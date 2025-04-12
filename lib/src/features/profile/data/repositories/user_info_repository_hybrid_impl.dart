// lib/src/features/profile/data/repositories/user_info_repository_hybrid_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/persistence/data_sync_manager.dart';
import '../../domain/entities/user_info.dart';
import '../../domain/repositories/user_info_respository.dart';
import 'user_info_repository_sqlite_impl.dart';
import 'user_info_repository_firestore_impl.dart';

/// A hybrid implementation of UserInfoRepository that combines local SQLite storage
/// with Firestore cloud storage. This implementation uses timestamp-based conflict
/// resolution to handle data conflicts between local and cloud storage.
class UserInfoRepositoryHybridImpl implements UserInfoRepository {
  final UserInfoRepositorySQLiteImpl _localRepository;
  final UserInfoRepositoryFirestoreImpl _cloudRepository;
  final firebase_auth.FirebaseAuth _auth;
  final Connectivity _connectivity;
  final DataSyncManager _syncManager;

  UserInfoRepositoryHybridImpl(
    this._localRepository,
    this._cloudRepository,
    this._auth,
    this._connectivity,
    this._syncManager,
  );

  // Helper method to check if user is authenticated
  bool get _isAuthenticated => _auth.currentUser != null;

  // Helper method to check network connectivity
  Future<bool> get _isOnline async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Future<List<UserInfo>> getSavedUserInfos() async {
    // Always get data from local storage first for immediate response
    final localUserInfos = await _localRepository.getSavedUserInfos();

    // If user is authenticated and online, trigger background sync
    if (_isAuthenticated && await _isOnline) {
      // Trigger background sync but don't wait for it
      _syncManager.syncUserProfiles().catchError((e) {
        print('Error syncing user profiles: $e');
      });
    }

    return localUserInfos;
  }

  @override
  Future<void> saveUserInfo(UserInfo userInfo) async {
    // Always save to local storage first
    await _localRepository.saveUserInfo(
      userInfo.copyWith(lastModified: DateTime.now()),
    );

    // If user is authenticated and online, save to cloud storage
    if (_isAuthenticated && await _isOnline) {
      try {
        await _cloudRepository.saveUserInfo(
          userInfo.copyWith(lastModified: DateTime.now()),
        );
      } catch (e) {
        print('Error saving user info to cloud: $e');
        // Continue even if cloud save fails
      }
    }
  }

  @override
  Future<void> deleteUserInfo(String id) async {
    // Always delete from local storage first
    await _localRepository.deleteUserInfo(id);

    // If user is authenticated and online, delete from cloud storage
    if (_isAuthenticated && await _isOnline) {
      try {
        await _cloudRepository.deleteUserInfo(id);
      } catch (e) {
        print('Error deleting user info from cloud: $e');
        // Continue even if cloud delete fails
      }
    }
  }

  @override
  Future<void> setDefaultUserInfo(String id) async {
    // Always set default in local storage first
    await _localRepository.setDefaultUserInfo(id);

    // If user is authenticated and online, set default in cloud storage
    if (_isAuthenticated && await _isOnline) {
      try {
        await _cloudRepository.setDefaultUserInfo(id);
      } catch (e) {
        print('Error setting default user info in cloud: $e');
        // Continue even if cloud operation fails
      }
    }
  }

  @override
  Future<UserInfo?> getDefaultUserInfo() async {
    // Always get default from local storage first for immediate response
    final localDefaultUserInfo = await _localRepository.getDefaultUserInfo();

    // If user is authenticated and online, trigger background sync
    if (_isAuthenticated && await _isOnline) {
      // Trigger background sync but don't wait for it
      _syncManager.syncUserProfiles().catchError((e) {
        print('Error syncing user profiles: $e');
      });
    }

    return localDefaultUserInfo;
  }

  /// Manually triggers synchronization of user profiles between local and cloud storage.
  /// This method is used by the UserInfoNotifier to force a sync operation.
  Future<void> syncUserProfiles() async {
    if (_isAuthenticated && await _isOnline) {
      await _syncManager.syncUserProfiles();
    }
  }
}
