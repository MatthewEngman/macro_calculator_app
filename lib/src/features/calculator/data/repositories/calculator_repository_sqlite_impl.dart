// lib/src/features/calculator/data/repositories/calculator_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/macro_result.dart';
import 'macro_calculation_db.dart';

class CalculatorRepositorySQLiteImpl {
  final firebase_auth.FirebaseAuth _auth;
  final MacroCalculationDB _macroCalculationDB;
  String? _userId; // Keep track of local User ID (users table PK)

  CalculatorRepositorySQLiteImpl(this._auth, this._macroCalculationDB);

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
    return await _macroCalculationDB.getAllCalculations(
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
    final existingResult = await _macroCalculationDB.getCalculationById(id);

    if (existingResult != null) {
      // Update existing result
      await _macroCalculationDB.insertCalculation(
        newResult,
        userId: _userId!, // Use localUserId
      );
    } else {
      // Add new result
      await _macroCalculationDB.insertCalculation(
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
    final result = await _macroCalculationDB.getCalculationById(id);
    if (result == null) return;

    await _macroCalculationDB.deleteCalculation(id);

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
    await _macroCalculationDB.setDefaultCalculation(
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
    return await _macroCalculationDB.getDefaultCalculation(
      userId: _userId!, // Use localUserId
    );
  }

  Future<MacroResult?> getMacroById(String id) async {
    return await _macroCalculationDB.getCalculationById(id);
  }
}
