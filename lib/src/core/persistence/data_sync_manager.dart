// lib/src/core/persistence/data_sync_manager.dart
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

class DataSyncManager {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  DataSyncManager(this._auth, this._firestore, this._connectivity);

  // Helper method to get the current user ID
  String? get _userId => _auth.currentUser?.uid;
  String get _requiredUserId {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User must be logged in to perform this operation');
    }
    return userId;
  }

  // Check if network is available
  Future<bool> isNetworkAvailable() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Sync user profiles
  Future<void> syncUserProfiles() async {
    if (_userId == null) return;
    if (!await isNetworkAvailable()) return;

    try {
      // Get local user profiles
      final localProfiles = await UserDB.getAllUsers(
        firebaseUserId: _requiredUserId,
      );

      // Get remote user profiles
      final remoteProfilesSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('user_infos')
              .get();

      // Create a map of remote profiles by ID for easier lookup
      final remoteProfilesMap = {
        for (var doc in remoteProfilesSnapshot.docs)
          doc.id: UserInfo.fromJson({...doc.data(), 'id': doc.id}),
      };

      // Sync local to remote
      for (var localProfile in localProfiles) {
        final profileId = localProfile.id!;
        final remoteProfile = remoteProfilesMap[profileId];

        if (remoteProfile == null) {
          // Profile exists locally but not remotely - upload it
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('user_infos')
              .doc(profileId)
              .set(localProfile.toJson());
        }
        // If both exist, we could implement a last-modified timestamp to determine which to keep
      }

      // Sync remote to local
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
          // Profile exists remotely but not locally - download it
          await UserDB.insertUser(remoteProfile, _requiredUserId);
        }
      }
    } catch (e) {
      print('Error syncing user profiles: $e');
    }
  }

  // Sync macro calculations
  Future<void> syncMacroCalculations() async {
    if (_userId == null) return;
    if (!await isNetworkAvailable()) return;

    try {
      // Get local calculations
      final localCalculations = await MacroCalculationDB.getAllCalculations(
        firebaseUserId: _userId,
      );

      // Get remote calculations
      final remoteCalculationsSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('macro_calculations')
              .get();

      // Create a map of remote calculations by ID for easier lookup
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
          ),
      };

      // Sync local to remote
      for (var localCalc in localCalculations) {
        final calcId = localCalc.id!;
        final remoteCalc = remoteCalculationsMap[calcId];

        if (remoteCalc == null) {
          // Calculation exists locally but not remotely - upload it
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
              });
        }
      }

      // Sync remote to local
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
          // Calculation exists remotely but not locally - download it
          await MacroCalculationDB.insertCalculation(
            remoteCalc,
            firebaseUserId: _userId,
          );
        }
      }
    } catch (e) {
      print('Error syncing macro calculations: $e');
    }
  }

  // Sync meal plans
  Future<void> syncMealPlans() async {
    if (_userId == null) return;
    if (!await isNetworkAvailable()) return;

    try {
      // Get local meal plans
      final localMealPlans = await MealPlanDB.getAllPlans();

      // Get remote meal plans
      final remoteMealPlansSnapshot =
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('meal_plans')
              .get();

      // Create a map of remote meal plans by ID for easier lookup
      final remoteMealPlansMap = {
        for (var doc in remoteMealPlansSnapshot.docs)
          doc.data()['id'].toString(): MealPlan.fromMap({
            ...doc.data(),
            'id': doc.data()['id'],
          }),
      };

      // Sync local to remote
      for (var localPlan in localMealPlans) {
        final planId = localPlan.id.toString();
        final remotePlan = remoteMealPlansMap[planId];

        if (remotePlan == null && localPlan.id != null) {
          // Meal plan exists locally but not remotely - upload it
          await _firestore
              .collection('users')
              .doc(_userId)
              .collection('meal_plans')
              .doc(planId)
              .set(localPlan.toMap());
        }
      }

      // Sync remote to local
      for (var entry in remoteMealPlansMap.entries) {
        final planId = int.tryParse(entry.key);
        final remotePlan = entry.value;

        if (planId != null) {
          final localPlan = localMealPlans.firstWhere(
            (plan) => plan.id == planId,
            orElse:
                () => MealPlan(
                  diet: '',
                  goal: '',
                  macros: {},
                  ingredients: [],
                  plan: '',
                ),
          );

          if (localPlan.id == null) {
            // Meal plan exists remotely but not locally - download it
            await MealPlanDB.insertMealPlan(remotePlan);
          }
        }
      }
    } catch (e) {
      print('Error syncing meal plans: $e');
    }
  }

  // Sync all data
  Future<void> syncAllData() async {
    await syncUserProfiles();
    await syncMacroCalculations();
    await syncMealPlans();
  }
}
