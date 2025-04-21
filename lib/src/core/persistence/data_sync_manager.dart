// lib/src/core/persistence/data_sync_manager.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';
import '../../features/profile/domain/entities/user_info.dart';
import '../../features/calculator/domain/entities/macro_result.dart';
import '../../features/meal_plan/models/meal_plan.dart';
import '../../features/profile/data/repositories/user_db.dart';
import '../../features/calculator/data/repositories/macro_calculation_db.dart';
import '../../features/meal_plan/data/meal_plan_db.dart';

enum SyncStatus { idle, syncing, synced, offline, error, notAuthenticated }

class DataSyncManager {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final UserDB _userDB;
  final MacroCalculationDB _macroCalculationDB;
  final MealPlanDB _mealPlanDB;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  DataSyncManager(
    this._auth,
    this._firestore,
    this._connectivity,
    this._userDB,
    this._macroCalculationDB,
    this._mealPlanDB,
  );

  String? get _userId => _auth.currentUser?.uid;
  String get _requiredUserId {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User must be logged in to perform this operation');
    }
    return userId;
  }

  void _updateSyncStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  Future<bool> isNetworkAvailable() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncUserProfiles() async {
    if (_userId == null) return;
    if (!await isNetworkAvailable()) {
      _updateSyncStatus(SyncStatus.offline);
      return;
    }

    try {
      _updateSyncStatus(SyncStatus.syncing);

      final localProfiles = await _userDB.getAllUsers(
        firebaseUserId: _requiredUserId,
      );

      final remoteProfilesSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('user_infos')
              .get();

      final remoteProfilesMap = {
        for (var doc in remoteProfilesSnapshot.docs)
          doc.id: UserInfo.fromJson({...doc.data(), 'id': doc.id}),
      };

      for (var localProfile in localProfiles) {
        final profileId = localProfile.id!;
        final remoteProfile = remoteProfilesMap[profileId];

        if (remoteProfile == null) {
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('user_infos')
              .doc(profileId)
              .set({
                ...localProfile.toJson(),
                'lastModified': FieldValue.serverTimestamp(),
              });
        } else {
          final localTimestamp = localProfile.lastModified ?? DateTime(1970);
          final remoteTimestamp = remoteProfile.lastModified ?? DateTime(1970);

          if (localTimestamp.isAfter(remoteTimestamp)) {
            await _firestore
                .collection('users')
                .doc(_userId)
                .collection('user_infos')
                .doc(profileId)
                .set({
                  ...localProfile.toJson(),
                  'lastModified': FieldValue.serverTimestamp(),
                });
          }
        }
      }

      for (var entry in remoteProfilesMap.entries) {
        final profileId = entry.key;
        final remoteProfile = entry.value;

        final localProfile = localProfiles.firstWhere(
          (profile) => profile.id == profileId,
          orElse:
              () => UserInfo(
                sex: 'male',
                activityLevel: ActivityLevel.moderatelyActive,
                goal: Goal.maintain,
                units: Units.imperial,
              ),
        );

        if (localProfile.id == null) {
          await _userDB.insertUser(remoteProfile, _requiredUserId);
        } else {
          final localTimestamp = localProfile.lastModified ?? DateTime(1970);
          final remoteTimestamp = remoteProfile.lastModified ?? DateTime(1970);

          if (remoteTimestamp.isAfter(localTimestamp)) {
            await _userDB.updateUser(remoteProfile, _requiredUserId);
          }
        }
      }

      _updateSyncStatus(SyncStatus.synced);
    } catch (e) {
      print('Error syncing user profiles: $e');
      _updateSyncStatus(SyncStatus.error);
    }
  }

  Future<void> syncMacroCalculations() async {
    if (_userId == null) return;
    if (!await isNetworkAvailable()) {
      _updateSyncStatus(SyncStatus.offline);
      return;
    }

    try {
      _updateSyncStatus(SyncStatus.syncing);

      final localUser = await _userDB.getUserByFirebaseId(_requiredUserId);
      if (localUser == null || localUser.id == null) {
        print(
          'DataSyncManager: Cannot sync macro calculations. Local user not found for firebase ID $_requiredUserId',
        );
        return;
      }
      final localUserId = localUser.id!;

      final localCalculations = await _macroCalculationDB.getAllCalculations(
        userId: localUserId,
      );

      final remoteCalculationsSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('macro_calculations')
              .get();

      final remoteCalculationsMap = {
        for (var doc in remoteCalculationsSnapshot.docs)
          doc.id: MacroResult(
            id: doc.id,
            calories: doc.data()['calories'],
            protein: doc.data()['protein'],
            carbs: doc.data()['carbs'],
            fat: doc.data()['fat'],
            calculationType: doc.data()['calculationType'],
            timestamp:
                doc.data()['timestamp'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                      doc.data()['timestamp'],
                    )
                    : DateTime.now(),
            isDefault: doc.data()['isDefault'] ?? false,
            name: doc.data()['name'],
            lastModified:
                doc.data()['lastModified'] != null
                    ? (doc.data()['lastModified'] as Timestamp).toDate()
                    : null,
          ),
      };

      for (var localCalc in localCalculations) {
        final calcId = localCalc.id!;
        final remoteCalc = remoteCalculationsMap[calcId];

        if (remoteCalc == null) {
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('macro_calculations')
              .doc(calcId)
              .set({
                'calories': localCalc.calories,
                'protein': localCalc.protein,
                'carbs': localCalc.carbs,
                'fat': localCalc.fat,
                'calculationType': localCalc.calculationType,
                'timestamp': localCalc.timestamp?.millisecondsSinceEpoch,
                'isDefault': localCalc.isDefault,
                'name': localCalc.name,
                'lastModified': FieldValue.serverTimestamp(),
              });
        } else {
          final localTimestamp = localCalc.lastModified ?? DateTime(1970);
          final remoteTimestamp = remoteCalc.lastModified ?? DateTime(1970);

          if (localTimestamp.isAfter(remoteTimestamp)) {
            await _firestore
                .collection('users')
                .doc(_userId)
                .collection('macro_calculations')
                .doc(calcId)
                .set({
                  'calories': localCalc.calories,
                  'protein': localCalc.protein,
                  'carbs': localCalc.carbs,
                  'fat': localCalc.fat,
                  'calculationType': localCalc.calculationType,
                  'timestamp': localCalc.timestamp?.millisecondsSinceEpoch,
                  'isDefault': localCalc.isDefault,
                  'name': localCalc.name,
                  'lastModified': FieldValue.serverTimestamp(),
                });
          }
        }
      }

      for (var entry in remoteCalculationsMap.entries) {
        final calcId = entry.key;
        final remoteCalc = entry.value;

        final localCalc = localCalculations.firstWhere(
          (calc) => calc.id == calcId,
          orElse:
              () => MacroResult(
                calories: 0,
                protein: 0,
                carbs: 0,
                fat: 0,
                calculationType: 'maintain',
              ),
        );

        if (localCalc.id == null) {
          await _macroCalculationDB.insertCalculation(
            remoteCalc,
            userId: localUserId,
          );
        } else {
          final localTimestamp = localCalc.lastModified ?? DateTime(1970);
          final remoteTimestamp = remoteCalc.lastModified ?? DateTime(1970);

          if (remoteTimestamp.isAfter(localTimestamp)) {
            await _macroCalculationDB.updateCalculation(
              remoteCalc,
              userId: localUserId,
            );
          }
        }
      }

      _updateSyncStatus(SyncStatus.synced);
    } catch (e) {
      print('Error syncing macro calculations: $e');
      _updateSyncStatus(SyncStatus.error);
    }
  }

  Future<void> syncMealPlans() async {
    if (_userId == null) return;
    if (!await isNetworkAvailable()) {
      _updateSyncStatus(SyncStatus.offline);
      return;
    }

    try {
      _updateSyncStatus(SyncStatus.syncing);

      final localUser = await _userDB.getUserByFirebaseId(_requiredUserId);
      if (localUser == null || localUser.id == null) {
        print(
          'DataSyncManager: Cannot sync meal plans. Local user not found for firebase ID $_requiredUserId',
        );
        _updateSyncStatus(SyncStatus.error); // Or appropriate status
        return;
      }
      final localUserId = localUser.id!;

      final localMealPlans = await _mealPlanDB.getAllPlans(userId: localUserId);

      final remoteMealPlansSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('meal_plans')
              .get();

      final remoteMealPlansMap = {
        for (var doc in remoteMealPlansSnapshot.docs)
          doc.data()['id'].toString(): MealPlan.fromMap({
            ...doc.data(),
            'id': doc.data()['id'],
            'lastModified':
                doc.data()['lastModified'] != null
                    ? (doc.data()['lastModified'] as Timestamp).toDate()
                    : null,
          }),
      };

      for (var localPlan in localMealPlans) {
        final planId = localPlan.id.toString();
        final remotePlan = remoteMealPlansMap[planId];

        if (remotePlan == null && localPlan.id != null) {
          final planMap = localPlan.toMap();
          planMap['lastModified'] = FieldValue.serverTimestamp();

          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('meal_plans')
              .doc(planId)
              .set(planMap);
        } else if (remotePlan != null && localPlan.id != null) {
          final localTimestamp = localPlan.lastModified ?? DateTime(1970);
          final remoteTimestamp = remotePlan.lastModified ?? DateTime(1970);

          if (localTimestamp.isAfter(remoteTimestamp)) {
            final planMap = localPlan.toMap();
            planMap['lastModified'] = FieldValue.serverTimestamp();

            await _firestore
                .collection('users')
                .doc(_userId)
                .collection('meal_plans')
                .doc(planId)
                .set(planMap);
          }
        }
      }

      for (var entry in remoteMealPlansMap.entries) {
        final planId = int.tryParse(entry.key);
        final remotePlan = entry.value;

        if (planId != null) {
          final localPlan = findLocalMealPlan(localMealPlans, remotePlan.id!);

          if (localPlan == null) {
            await _mealPlanDB.insertMealPlan(remotePlan, localUserId);
          } else {
            final localTimestamp = localPlan.lastModified ?? DateTime(1970);
            final remoteTimestamp = remotePlan.lastModified ?? DateTime(1970);

            if (remoteTimestamp.isAfter(localTimestamp)) {
              await _mealPlanDB.updateMealPlan(remotePlan);
            }
          }
        }
      }

      _updateSyncStatus(SyncStatus.synced);
    } catch (e) {
      print('Error syncing meal plans: $e');
      _updateSyncStatus(SyncStatus.error);
    }
  }

  MealPlan? findLocalMealPlan(List<MealPlan> plans, String id) {
    try {
      return plans.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> syncAllData() async {
    if (_currentStatus == SyncStatus.syncing) return;

    if (!await isNetworkAvailable()) {
      _updateSyncStatus(SyncStatus.offline);
      return;
    }

    if (_auth.currentUser == null) {
      _updateSyncStatus(SyncStatus.notAuthenticated);
      return;
    }

    _updateSyncStatus(SyncStatus.syncing);

    try {
      await syncUserProfiles();
      await syncMacroCalculations();
      await syncMealPlans();

      _updateSyncStatus(SyncStatus.synced);

      // After a delay, set back to idle
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentStatus == SyncStatus.synced) {
          _updateSyncStatus(SyncStatus.idle);
        }
      });
    } catch (e) {
      _updateSyncStatus(SyncStatus.error);
    }
  }
}
