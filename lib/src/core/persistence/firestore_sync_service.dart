import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:macro_masher/src/core/persistence/local_storage_service.dart'; // update path as needed
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart';

class FirestoreSyncService {
  static FirestoreSyncService? _instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService;
  List<Map<String, dynamic>> _syncQueue = [];
  StreamSubscription? _userDataSubscription;

  FirestoreSyncService._internal(this._localStorageService);

  factory FirestoreSyncService() {
    if (_instance == null) {
      throw Exception(
        'FirestoreSyncService not initialized. Call FirestoreSyncService.initialize() first.',
      );
    }
    return _instance!;
  }

  static Future<void> initialize(
    LocalStorageService localStorageService,
  ) async {
    if (_instance == null) {
      _instance = FirestoreSyncService._internal(localStorageService);
      await _instance!._init();
    }
  }

  Future<void> _init() async {
    await _loadQueue();

    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        processSyncQueue();
      }
    });
  }

  Future<bool> checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncUserData(UserInfo user) async {
    try {
      bool isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        _addToSyncQueue({
          'operation': 'sync_user',
          'data': user.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      }
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
      await _localStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      _addToSyncQueue({
        'operation': 'sync_user',
        'data': user.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void _addToSyncQueue(Map<String, dynamic> item) {
    _syncQueue.add(item);
    _saveQueue();
  }

  Future<void> processSyncQueue() async {
    if (_syncQueue.isEmpty) return;
    bool isConnected = await checkInternetConnectivity();
    if (!isConnected) return;
    List<Map<String, dynamic>> processedItems = [];
    for (var item in _syncQueue) {
      try {
        switch (item['operation']) {
          case 'sync_user':
            await _firestore
                .collection('users')
                .doc(item['data']['id'])
                .set(item['data'], SetOptions(merge: true));
            processedItems.add(item);
            break;
          case 'save_user_info':
            final userId = item['userId'];
            final userInfo = UserInfo.fromJson(item['data']);
            final collectionPath = 'users/$userId/user_infos';

            if (userInfo.id != null) {
              await _firestore
                  .collection(collectionPath)
                  .doc(userInfo.id)
                  .set(userInfo.toJson());
            } else {
              final docRef = await _firestore
                  .collection(collectionPath)
                  .add(userInfo.toJson());

              await docRef.update({'id': docRef.id});
            }
            processedItems.add(item);
            break;
          case 'delete_user_info':
            final userId = item['userId'];
            final id = item['id'];
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('user_infos')
                .doc(id)
                .delete();
            processedItems.add(item);
            break;
          case 'set_default_user_info':
            final userId = item['userId'];
            final id = item['id'];
            final batch = _firestore.batch();
            final snapshot =
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('user_infos')
                    .get();

            for (final doc in snapshot.docs) {
              batch.update(doc.reference, {'isDefault': doc.id == id});
            }

            await batch.commit();
            processedItems.add(item);
            break;
          // Add cases for food logs, measurements, etc.
        }
      } catch (_) {
        // Leave in queue for retry
      }
    }
    for (var item in processedItems) {
      _syncQueue.remove(item);
    }
    _saveQueue();
  }

  Future<void> _saveQueue() async {
    await _localStorageService.setSyncQueue(_syncQueue);
  }

  Future<void> _loadQueue() async {
    _syncQueue = await _localStorageService.getSyncQueue() ?? [];
  }

  // Real-time listener example
  void startUserDataListener(String userId, void Function(UserInfo) onUpdate) {
    _userDataSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>;
            final user = UserInfo.fromJson(userData);
            _localStorageService.saveUser(user);
            onUpdate(user);
          }
        });
  }

  void stopUserDataListener() {
    _userDataSubscription?.cancel();
    _userDataSubscription = null;
  }

  // Add other CRUD and conflict resolution methods as needed
  // User Info operations
  Future<List<UserInfo>> getSavedUserInfos(String userId) async {
    try {
      bool isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        // Return from local storage if offline
        return await _localStorageService.getSavedUserInfos(userId) ?? [];
      }

      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('user_infos')
              .get();

      final userInfos =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return UserInfo.fromJson(data);
          }).toList();

      // Update local cache
      await _localStorageService.saveUserInfos(userId, userInfos);
      return userInfos;
    } catch (e) {
      // Fallback to local storage on error
      return await _localStorageService.getSavedUserInfos(userId) ?? [];
    }
  }

  Future<void> saveUserInfo(String userId, UserInfo userInfo) async {
    if (userId == '') {
      throw Exception('User not authenticated');
    }

    final userInfoWithId =
        userInfo.id == null
            ? userInfo.copyWith(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
            )
            : userInfo;

    try {
      // Save to local storage first
      await _localStorageService.saveUserInfo(userId, userInfoWithId);

      bool isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        _addToSyncQueue({
          'operation': 'save_user_info',
          'userId': userId,
          'data': userInfoWithId.toJson(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      }

      final collectionPath = 'users/$userId/user_infos';

      if (userInfoWithId.id != null) {
        // Update existing user info
        await _firestore
            .collection(collectionPath)
            .doc(userInfoWithId.id)
            .set(userInfoWithId.toJson());
      } else {
        // Add new user info
        final docRef = await _firestore
            .collection(collectionPath)
            .add(userInfoWithId.toJson());

        // Update the document with its ID
        final updatedUserInfo = userInfoWithId.copyWith(id: docRef.id);
        await docRef.update({'id': docRef.id});

        // Update local storage with the new ID
        await _localStorageService.saveUserInfo(userId, updatedUserInfo);
      }
    } catch (e) {
      // Queue for retry on error
      _addToSyncQueue({
        'operation': 'save_user_info',
        'userId': userId,
        'data': userInfoWithId.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> deleteUserInfo(String userId, String id) async {
    if (userId == '') {
      throw Exception('User not authenticated');
    }

    try {
      // Delete from local storage first
      await _localStorageService.deleteUserInfo(userId, id);

      bool isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        _addToSyncQueue({
          'operation': 'delete_user_info',
          'userId': userId,
          'id': id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_infos')
          .doc(id)
          .delete();
    } catch (e) {
      // Queue for retry on error
      _addToSyncQueue({
        'operation': 'delete_user_info',
        'userId': userId,
        'id': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> setDefaultUserInfo(String userId, String id) async {
    if (userId == '') {
      throw Exception('User not authenticated');
    }

    try {
      // Update local storage first
      await _localStorageService.setDefaultUserInfo(userId, id);

      bool isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        _addToSyncQueue({
          'operation': 'set_default_user_info',
          'userId': userId,
          'id': id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      }

      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('user_infos')
              .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': doc.id == id});
      }

      await batch.commit();
    } catch (e) {
      // Queue for retry on error
      _addToSyncQueue({
        'operation': 'set_default_user_info',
        'userId': userId,
        'id': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<UserInfo?> getDefaultUserInfo(String userId) async {
    if (userId == '') {
      return null;
    }

    try {
      // First try to get from local storage to avoid read-only issues
      final localUserInfo = await _localStorageService.getDefaultUserInfo(
        userId,
      );
      if (localUserInfo != null &&
          localUserInfo.name != null &&
          localUserInfo.age != null &&
          localUserInfo.weight != null) {
        print(
          'FirestoreSyncService: Using complete user info from local storage',
        );
        return localUserInfo;
      }

      bool isConnected = await checkInternetConnectivity();
      if (!isConnected) {
        // Return from local storage if offline
        return localUserInfo;
      }

      // Try to get from Firestore
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('user_infos')
              .where('isDefault', isEqualTo: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        // If no default user info is found, get all user infos and use the first one
        final allUserInfos = await getSavedUserInfos(userId);

        // Find the most complete user info
        UserInfo? mostCompleteUserInfo;
        for (final userInfo in allUserInfos) {
          if (userInfo.name != null &&
              userInfo.age != null &&
              userInfo.weight != null &&
              userInfo.feet != null &&
              userInfo.inches != null) {
            // This is a complete user info, use it
            mostCompleteUserInfo = userInfo;
            break;
          }
        }

        // If no complete user info is found, use the first one
        final defaultUserInfo =
            mostCompleteUserInfo ??
            (allUserInfos.isNotEmpty ? allUserInfos.first : null);

        // Cache the result
        if (defaultUserInfo != null) {
          try {
            await _localStorageService.saveUserInfo(userId, defaultUserInfo);
          } catch (e) {
            print('FirestoreSyncService: Error caching user info: $e');
          }
        }

        return defaultUserInfo;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      final userInfo = UserInfo.fromJson(data);

      // Cache the result
      try {
        await _localStorageService.saveUserInfo(userId, userInfo);
      } catch (e) {
        print('FirestoreSyncService: Error caching user info: $e');
      }

      return userInfo;
    } catch (e) {
      print('FirestoreSyncService: Error getting default user info: $e');
      // Fallback to local storage on error
      return await _localStorageService.getDefaultUserInfo(userId);
    }
  }
}
