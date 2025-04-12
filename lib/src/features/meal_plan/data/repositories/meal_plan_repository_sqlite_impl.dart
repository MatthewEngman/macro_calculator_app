// lib/src/features/meal_plan/data/repositories/meal_plan_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/meal_plan.dart';
import '../meal_plan_db.dart';
import '../meal_log_db.dart';
import '../../models/meal_log.dart';

class MealPlanRepositorySQLiteImpl {
  final firebase_auth.FirebaseAuth _auth;

  MealPlanRepositorySQLiteImpl(this._auth);

  // Helper method to get the current user ID
  String? get _userId => _auth.currentUser?.uid;
  String get _requiredUserId {
    final userId = _userId;
    if (userId == null) {
      throw StateError('User must be logged in to perform this operation');
    }
    return userId;
  }

  Future<List<MealPlan>> getAllMealPlans() async {
    return await MealPlanDB.getAllPlans();
  }

  Future<int> saveMealPlan(MealPlan mealPlan) async {
    return await MealPlanDB.insertMealPlan(mealPlan);
  }

  Future<MealPlan?> getMealPlanById(int id) async {
    return await MealPlanDB.getMealPlan(id);
  }

  Future<int> updateMealPlanFeedback(int id, String feedback) async {
    return await MealPlanDB.updateFeedback(id, feedback);
  }

  Future<int> deleteMealPlan(int id) async {
    return await MealPlanDB.deleteMealPlan(id);
  }

  // Meal logging methods
  Future<List<MealLog>> getMealLogsForDay(DateTime date) async {
    return await MealLogDB.getMealLogsForDay(
      date,
      firebaseUserId: _requiredUserId,
    );
  }

  Future<List<MealLog>> getMealLogsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await MealLogDB.getMealLogsForDateRange(
      startDate,
      endDate,
      firebaseUserId: _requiredUserId,
    );
  }

  Future<String> saveMealLog(MealLog mealLog) async {
    return await MealLogDB.insertMealLog(mealLog);
  }

  Future<int> deleteMealLog(String id) async {
    return await MealLogDB.deleteMealLog(id);
  }
}
