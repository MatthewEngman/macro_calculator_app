// lib/src/features/meal_plan/data/repositories/meal_plan_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import '../../models/meal_plan.dart';
import '../meal_plan_db.dart'; // Keep this import
// Import uuid if you plan to use it for ID generation
// import 'package:uuid/uuid.dart';

class MealPlanRepositorySQLiteImpl {
  final MealPlanDB _mealPlanDB; // Add MealPlanDB instance
  final UserDB _userDB;
  String? _firebaseUserId;
  String? _localUserId; // Add localUserId field

  // Update constructor to accept MealPlanDB
  MealPlanRepositorySQLiteImpl(
    this._mealPlanDB,
    this._userDB, // <<< Ensure this parameter is present
  ) {
    // Body should be like this:
    _initializeUserIds();
  }

  // Initialize both Firebase and local user IDs
  Future<void> _initializeUserIds() async {
    // Get Firebase User ID directly from FirebaseAuth
    _firebaseUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (_firebaseUserId != null) {
      // Directly query UserDB to find the local user associated with the Firebase ID
      print(
        'MealPlanRepositorySQLiteImpl: Querying UserDB for local user ID associated with Firebase ID $_firebaseUserId.',
      );
      // TODO: Update this static call if/when UserDB is fully instance-based and provided
      final userFromDb = await _userDB.getUserByFirebaseId(
        // <<< Change _mealPlanDB back to _userDB
        _firebaseUserId!,
      ); // Use UserDB directly
      _localUserId =
          userFromDb
              ?.id; // Get local ID from the UserInfo object returned by UserDB

      if (_localUserId == null) {
        print(
          'MealPlanRepositorySQLiteImpl: No local user found in UserDB for Firebase ID $_firebaseUserId.',
        );
      }
    } else {
      // Handle case where there is no Firebase user logged in
      _localUserId = null; // Ensure local ID is also null
      print('MealPlanRepositorySQLiteImpl: No Firebase user logged in.');
    }
    // TODO: Consider adding listeners for auth changes to update IDs
    print(
      'MealPlanRepositorySQLiteImpl Initialized: FirebaseID=$_firebaseUserId, LocalID=$_localUserId',
    );
  }

  // Helper to ensure local user ID is available before DB operations
  Future<String?> _ensureLocalUserId() async {
    if (_localUserId == null) {
      print(
        'MealPlanRepositorySQLiteImpl: Local user ID is null, attempting re-initialization.',
      );
      await _initializeUserIds(); // Attempt re-initialization
    }
    if (_localUserId == null) {
      // This indicates a problem - user is likely not logged in or profile data is missing
      print(
        'Error: MealPlanRepositorySQLiteImpl - Local user ID could not be determined after initialization.',
      );
      // Depending on the desired behavior, you might throw an error here
      // or allow operations that don't strictly require a user ID.
    }
    return _localUserId;
  }

  // --- Meal Plan Methods ---

  Future<List<MealPlan>> getAllMealPlans() async {
    final userId = await _ensureLocalUserId();
    if (userId == null) {
      print('Error: Cannot get meal plans, user not initialized.');
      return []; // Return empty list if user ID is not available
    }
    // Ensure MealPlanDB.getAllPlansForUser expects and uses the userId
    // Use the instance _mealPlanDB
    return await _mealPlanDB.getAllPlansForUser(userId);
  }

  Future<String?> saveMealPlan(MealPlan plan) async {
    final userId = await _ensureLocalUserId();
    if (userId == null) {
      print('Error: Cannot save meal plan, user not initialized.');
      return null;
    }
    // Ensure the plan has the correct userId and a generated ID if missing
    final planToSave = plan.copyWith(
      userId: userId,
      // Generate ID if null - requires uuid package and uncommenting
      // id: plan.id ?? Uuid().v4(),
    );

    // Check if ID is still null after potential generation (important if not generating above)
    if (planToSave.id == null) {
      print('Error: Cannot save meal plan, ID is null.');
      // Consider generating ID here if not done above, or return error
      // planToSave = planToSave.copyWith(id: Uuid().v4()); // Example
      // if (planToSave.id == null) return null; // Still failed
      return null; // Return null if ID is required and missing
    }

    try {
      // Ensure MealPlanDB.insertMealPlan handles the plan and optionally the userId
      // If insertMealPlan uses planToSave.userId internally, passing userId might be redundant
      // Use the instance _mealPlanDB
      await _mealPlanDB.insertMealPlan(planToSave, userId);
      return planToSave.id;
    } catch (e) {
      print('Error saving meal plan to DB: $e');
      return null;
    }
  }

  Future<MealPlan?> getMealPlanById(String id) async {
    // Fetch the plan using MealPlanDB
    // Use the instance _mealPlanDB
    final plan = await _mealPlanDB.getMealPlanById(id);

    // Optional but recommended: Verify ownership
    final userId = await _ensureLocalUserId();
    if (plan != null && userId != null && plan.userId != userId) {
      print('Error: Meal plan $id does not belong to user $userId.');
      return null;
    }
    return plan;
  }

  // Add the missing deleteMealPlan method
  Future<int> deleteMealPlan(String id) async {
    // Optional: Add user ownership check here if needed before deleting
    // final userId = await _ensureLocalUserId();
    // if (userId == null) {
    //   print('Error: Cannot delete meal plan, user not initialized.');
    //   return 0; // Indicate failure
    // }
    // // Optional: Fetch plan first to verify ownership
    // final plan = await getMealPlanById(id);
    // if (plan == null || plan.userId != userId) {
    //   print('Error: Cannot delete meal plan $id, not found or not owned by user $userId.');
    //   return 0;
    // }

    // Call the instance method in MealPlanDB to perform the deletion
    // Use the instance _mealPlanDB
    return await _mealPlanDB.deleteMealPlan(id);
  }
}
