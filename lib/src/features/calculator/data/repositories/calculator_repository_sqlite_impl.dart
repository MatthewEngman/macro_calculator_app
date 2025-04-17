// lib/src/features/calculator/data/repositories/calculator_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/macro_result.dart';
import 'macro_calculation_db.dart';

class CalculatorRepositorySQLiteImpl {
  final firebase_auth.FirebaseAuth _auth;
  String? _userId; // Keep track of local User ID (users table PK)

  CalculatorRepositorySQLiteImpl(this._auth);

  // Helper method to get the current user ID
  String? get userId => _auth.currentUser?.uid;

  Future<void> _initializeUserId() async {
    // TODO: Initialize _userId, possibly by querying LocalStorageService for the corresponding local ID.
  }

  Future<List<MacroResult>> getSavedMacros() async {
    // TODO: Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId(); // Attempt re-initialization
      if (_userId == null) return []; // Return empty if still null
    }
    return await MacroCalculationDB.getAllCalculations(
      userId: _userId!, // Use localUserId
    );
  }

  Future<void> saveMacro(MacroResult result) async {
    // TODO: Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId();
      if (_userId == null) throw Exception('User not initialized');
    }
    final id = result.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newResult = result.copyWith(id: id);

    // Check if we're updating an existing result
    final existingResult = await MacroCalculationDB.getCalculationById(id);

    if (existingResult != null) {
      // Update existing result
      await MacroCalculationDB.insertCalculation(
        newResult,
        userId: _userId!, // Use localUserId
      );
    } else {
      // Add new result
      await MacroCalculationDB.insertCalculation(
        newResult,
        userId: _userId!, // Use localUserId
      );

      // If this result is set as default, update all others to not be default
      if (newResult.isDefault) {
        await setDefaultMacro(id);
      }
    }
  }

  Future<void> deleteMacro(String id) async {
    final result = await MacroCalculationDB.getCalculationById(id);
    if (result == null) return;

    await MacroCalculationDB.deleteCalculation(id);

    // If the deleted result was the default one, set a new default
    if (result.isDefault) {
      final allResults = await getSavedMacros();
      if (allResults.isNotEmpty) {
        await setDefaultMacro(allResults.first.id!);
      }
    }
  }

  Future<void> setDefaultMacro(String id) async {
    // TODO: Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId();
      if (_userId == null) throw Exception('User not initialized');
    }
    await MacroCalculationDB.setDefaultCalculation(
      id,
      userId: _userId!, // Use localUserId
    );
  }

  Future<MacroResult?> getDefaultMacro() async {
    // TODO: Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId();
      if (_userId == null) return null;
    }
    return await MacroCalculationDB.getDefaultCalculation(
      userId: _userId!, // Use localUserId
    );
  }

  Future<MacroResult?> getMacroById(String id) async {
    return await MacroCalculationDB.getCalculationById(id);
  }
}
