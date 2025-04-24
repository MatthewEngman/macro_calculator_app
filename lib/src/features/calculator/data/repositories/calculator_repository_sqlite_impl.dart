// lib/src/features/calculator/data/repositories/calculator_repository_sqlite_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/macro_result.dart';
import 'macro_calculation_db.dart';

class CalculatorRepositorySQLiteImpl {
  final firebase_auth.FirebaseAuth _auth;
  final MacroCalculationDB _macroCalculationDB;
  String? _userId; // Keep track of local User ID (users table PK)

  CalculatorRepositorySQLiteImpl(this._auth)
    : _macroCalculationDB = MacroCalculationDB() {
    // Initialize user ID as soon as the repository is created
    _initializeUserId();
  }

  // Helper method to get the current user ID
  String? get userId => _auth.currentUser?.uid;

  Future<void> _initializeUserId() async {
    // Get the Firebase user ID
    final firebaseUserId = userId;
    if (firebaseUserId == null) {
      return;
    }

    // Use the Firebase user ID directly as the local user ID
    // This simplifies the implementation and avoids the need for a separate local ID
    _userId = firebaseUserId;
  }

  Future<List<MacroResult>> getSavedMacros() async {
    // Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId(); // Attempt re-initialization
      if (_userId == null) return []; // Return empty if still null
    }

    try {
      return await _macroCalculationDB.executeWithRecovery((Database db) async {
        return await _macroCalculationDB.getAllCalculations(
          userId: _userId!, // Use localUserId
        );
      });
    } catch (e) {
      print('Error getting saved macros: $e');
      return []; // Return empty list on error
    }
  }

  Future<void> saveMacro(MacroResult result) async {
    // Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId();
      if (_userId == null) throw Exception('User not initialized');
    }

    try {
      final id = result.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final newResult = result.copyWith(id: id);

      // Check if we're updating an existing result
      final existingResult = await _macroCalculationDB.executeWithRecovery((
        Database db,
      ) async {
        return await _macroCalculationDB.getCalculationById(id);
      });

      // Insert the calculation with recovery mechanism
      await _macroCalculationDB.executeWithRecovery((Database db) async {
        await _macroCalculationDB.insertCalculation(
          newResult,
          _userId!, // Use localUserId
        );
      });

      // If this result is set as default, update all others to not be default
      if (newResult.isDefault) {
        await setDefaultMacro(id);
      }
    } catch (e) {
      rethrow; // Propagate the error
    }
  }

  Future<void> deleteMacro(String id) async {
    try {
      final result = await _macroCalculationDB.executeWithRecovery((
        Database db,
      ) async {
        return await _macroCalculationDB.getCalculationById(id);
      });
      if (result == null) return;

      await _macroCalculationDB.executeWithRecovery((Database db) async {
        await _macroCalculationDB.deleteCalculation(id);
      });

      // If the deleted result was the default one, set a new default
      if (result.isDefault) {
        final allResults = await getSavedMacros();
        if (allResults.isNotEmpty) {
          await setDefaultMacro(allResults.first.id!);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setDefaultMacro(String id) async {
    // Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId();
      if (_userId == null) throw Exception('User not initialized');
    }

    try {
      await _macroCalculationDB.executeWithRecovery((Database db) async {
        await _macroCalculationDB.setDefaultCalculation(
          id: id, // Use named parameter
          userId: _userId!, // Use localUserId
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<MacroResult?> getDefaultMacro() async {
    // Ensure _userId is initialized before calling
    if (_userId == null) {
      await _initializeUserId();
      if (_userId == null) return null;
    }

    try {
      final result = await _macroCalculationDB.executeWithRecovery((
        Database db,
      ) async {
        return await _macroCalculationDB.getDefaultCalculation(
          userId: _userId!, // Use localUserId
        );
      });
      return result;
    } catch (e) {
      return null; // Return null on error
    }
  }

  Future<MacroResult?> getMacroById(String id) async {
    try {
      return await _macroCalculationDB.executeWithRecovery((Database db) async {
        return await _macroCalculationDB.getCalculationById(id);
      });
    } catch (e) {
      return null; // Return null on error
    }
  }
}
