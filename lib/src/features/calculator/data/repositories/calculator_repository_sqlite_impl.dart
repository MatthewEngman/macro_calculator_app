// lib/src/features/calculator/data/repositories/calculator_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/macro_result.dart';
import 'macro_calculation_db.dart';

class CalculatorRepositorySQLiteImpl {
  final firebase_auth.FirebaseAuth _auth;

  CalculatorRepositorySQLiteImpl(this._auth);

  // Helper method to get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  Future<List<MacroResult>> getSavedMacros() async {
    return await MacroCalculationDB.getAllCalculations(firebaseUserId: _userId);
  }

  Future<void> saveMacro(MacroResult result) async {
    final id = result.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newResult = result.copyWith(id: id);

    // Check if we're updating an existing result
    final existingResult = await MacroCalculationDB.getCalculationById(id);

    if (existingResult != null) {
      // Update existing result
      await MacroCalculationDB.insertCalculation(
        newResult,
        firebaseUserId: _userId,
      );
    } else {
      // Add new result
      await MacroCalculationDB.insertCalculation(
        newResult,
        firebaseUserId: _userId,
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
    await MacroCalculationDB.setDefaultCalculation(id, firebaseUserId: _userId);
  }

  Future<MacroResult?> getDefaultMacro() async {
    return await MacroCalculationDB.getDefaultCalculation(
      firebaseUserId: _userId,
    );
  }

  Future<MacroResult?> getMacroById(String id) async {
    return await MacroCalculationDB.getCalculationById(id);
  }
}
