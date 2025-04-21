import 'package:macro_masher/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import '../../../calculator/domain/entities/macro_result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart'
    as app_models;
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';

class ProfileRepositoryHybridImpl implements ProfileRepository {
  final FirestoreSyncService syncService;
  final MacroCalculationDB _macroDB =
      MacroCalculationDB(); // Direct instance for cache access

  // In-memory cache for the most recently calculated valid macro result
  static MacroResult? _lastValidMacroResult;

  ProfileRepositoryHybridImpl(this.syncService);

  String get _userId {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  @override
  Future<List<MacroResult>> getSavedMacros() async {
    final userInfos = await syncService.getSavedUserInfos(_userId);
    return userInfos.map((u) => MacroResult.fromUserInfo(u)).toList();
  }

  @override
  Future<void> saveMacro(MacroResult result) async {
    final userInfo = result.toUserInfo();
    await syncService.saveUserInfo(_userId, userInfo);
  }

  @override
  Future<void> deleteMacro(String id) async {
    await syncService.deleteUserInfo(_userId, id);
  }

  @override
  Future<void> setDefaultMacro(String id) async {
    await syncService.setDefaultUserInfo(_userId, id);
  }

  @override
  Future<MacroResult?> getDefaultMacro() async {
    try {
      print(
        'ProfileRepositoryHybridImpl: Getting default macro for user $_userId',
      );

      // First try to get from MacroCalculationDB which has in-memory cache
      final macroResult = await _macroDB.getDefaultCalculation(userId: _userId);

      if (macroResult != null) {
        print(
          'ProfileRepositoryHybridImpl: Found default macro in MacroCalculationDB',
        );
        print('ID: ${macroResult.id}, Calories: ${macroResult.calories}');

        // Check if the macro result has valid values
        if (macroResult.calories > 0 && macroResult.protein > 0) {
          // Cache this valid result for future fallbacks
          _lastValidMacroResult = macroResult;
          return macroResult;
        } else {
          print(
            'ProfileRepositoryHybridImpl: Found macro has zero values, will try to find better data',
          );
        }
      }

      // If not found in MacroCalculationDB or values are zero, try the FirestoreSyncService
      print(
        'ProfileRepositoryHybridImpl: Trying FirestoreSyncService for complete user info',
      );
      final userInfo = await syncService.getDefaultUserInfo(_userId);

      // Check if we have a complete user info that can be used for calculation
      if (userInfo != null && _isUserInfoComplete(userInfo)) {
        print('ProfileRepositoryHybridImpl: Found complete user info');
        print('ID: ${userInfo.id}, Name: ${userInfo.name}');
        print('Age: ${userInfo.age}, Sex: ${userInfo.sex}');
        print(
          'Weight: ${userInfo.weight}, Height: ${userInfo.feet}\'${userInfo.inches}"',
        );
        print(
          'Units: ${userInfo.units}, Activity: ${userInfo.activityLevel}, Goal: ${userInfo.goal}',
        );

        // Create a macro result from the user info
        final macroResultFromUserInfo = MacroResult.fromUserInfo(userInfo);

        // Check if the calculation produced valid values
        if (macroResultFromUserInfo.calories > 0 &&
            macroResultFromUserInfo.protein > 0) {
          print(
            'ProfileRepositoryHybridImpl: Created valid macro result from user info',
          );
          print('User Info ID: ${userInfo.id}, Units: ${userInfo.units}');
          print(
            'Calculated Macros: ${macroResultFromUserInfo.calories} kcal, ${macroResultFromUserInfo.protein}g protein, ${macroResultFromUserInfo.carbs}g carbs, ${macroResultFromUserInfo.fat}g fat',
          );

          // Save this calculation to MacroCalculationDB to update the cache
          if (macroResultFromUserInfo.id != null) {
            print(
              'ProfileRepositoryHybridImpl: Saving valid macro to MacroCalculationDB',
            );
            await _macroDB.insertCalculation(
              macroResultFromUserInfo.copyWith(isDefault: true),
              userId: _userId,
            );
          }

          // Cache this valid result for future fallbacks
          _lastValidMacroResult = macroResultFromUserInfo;
          return macroResultFromUserInfo;
        } else {
          print(
            'ProfileRepositoryHybridImpl: Calculation produced invalid values',
          );
        }
      } else if (userInfo != null) {
        print('ProfileRepositoryHybridImpl: User info is incomplete');
        print('Missing fields: ${_getMissingFields(userInfo)}');
      }

      // If we reach here, we couldn't get valid macro values from DB or FirestoreSyncService
      // Try to use the last valid macro result as a fallback
      if (_lastValidMacroResult != null) {
        print(
          'ProfileRepositoryHybridImpl: Using last valid macro result as fallback',
        );
        print(
          'ID: ${_lastValidMacroResult!.id}, Calories: ${_lastValidMacroResult!.calories}',
        );
        return _lastValidMacroResult;
      }

      // As a last resort, try to get any saved macro from the database
      print(
        'ProfileRepositoryHybridImpl: Trying to find any valid saved macro',
      );
      final savedMacros = await getSavedMacros();
      final validMacro = savedMacros.firstWhere(
        (macro) => macro.calories > 0 && macro.protein > 0,
        orElse:
            () => MacroResult(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              calories: 2000, // Default fallback values
              protein: 150,
              carbs: 200,
              fat: 67,
              calculationType: 'default_fallback',
              isDefault: true,
              name: 'Default Fallback',
              lastModified: DateTime.now(),
            ),
      );

      print(
        'ProfileRepositoryHybridImpl: Using valid macro: ${validMacro.id}, Calories: ${validMacro.calories}',
      );
      _lastValidMacroResult = validMacro;
      return validMacro;
    } catch (e) {
      print('ProfileRepositoryHybridImpl: Error getting default macro: $e');

      // Even on error, try to return the last valid result if available
      if (_lastValidMacroResult != null) {
        print(
          'ProfileRepositoryHybridImpl: Returning last valid result after error',
        );
        return _lastValidMacroResult;
      }

      // Create a default fallback macro if nothing else is available
      return MacroResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        calories: 2000, // Default fallback values
        protein: 150,
        carbs: 200,
        fat: 67,
        calculationType: 'error_fallback',
        isDefault: true,
        name: 'Error Fallback',
        lastModified: DateTime.now(),
      );
    }
  }

  // Helper method to check if user info has all required fields for calculation
  bool _isUserInfoComplete(app_models.UserInfo userInfo) {
    return userInfo.age != null &&
        userInfo.weight != null &&
        (userInfo.units == Units.metric ||
            (userInfo.feet != null && userInfo.inches != null));
  }

  // Helper method to get a list of missing fields for debugging
  String _getMissingFields(app_models.UserInfo userInfo) {
    final missingFields = <String>[];

    if (userInfo.age == null) missingFields.add('age');
    if (userInfo.weight == null) missingFields.add('weight');
    if (userInfo.units == Units.imperial &&
        (userInfo.feet == null || userInfo.inches == null)) {
      missingFields.add('height');
    }

    return missingFields.join(', ');
  }
}
