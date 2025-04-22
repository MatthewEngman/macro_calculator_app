import 'package:macro_masher/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import '../../../calculator/domain/entities/macro_result.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';
import 'package:macro_masher/src/features/profile/domain/entities/user_info.dart'
    as app_models;
import 'package:macro_masher/src/features/profile/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileRepositoryHybridImpl implements ProfileRepository {
  final FirestoreSyncService syncService;
  final MacroCalculationDB _macroDB =
      MacroCalculationDB(); // Direct instance for cache access

  // In-memory cache for the most recently calculated valid macro result
  static MacroResult? _lastValidMacroResult;

  ProfileRepositoryHybridImpl(this.syncService);

  String _getUserId(String? userId) {
    if (userId != null) return userId;

    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  // Synchronize database data with SharedPreferences for backup
  Future<void> _syncToSharedPreferences(String userId) async {
    try {
      print(
        'ProfileRepositoryHybridImpl: Syncing data to SharedPreferences for user $userId',
      );

      // Get calculations from database
      final calculations = await _macroDB.getAllCalculations(userId: userId);

      if (calculations.isEmpty) {
        print('No calculations to sync to SharedPreferences');
        return;
      }

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      final key = 'saved_macros_$userId';

      // Convert calculations to JSON
      final jsonData =
          calculations
              .map(
                (calc) => {
                  'id': calc.id,
                  'calories': calc.calories,
                  'protein': calc.protein,
                  'carbs': calc.carbs,
                  'fat': calc.fat,
                  'timestamp': calc.timestamp?.toIso8601String(),
                  'isDefault': calc.isDefault,
                  'userId': calc.userId,
                  'name': calc.name,
                  'calculationType': calc.calculationType,
                  'lastModified': calc.lastModified?.toIso8601String(),
                },
              )
              .toList();

      // Save to SharedPreferences
      await prefs.setString(key, json.encode(jsonData));
      print(
        'ProfileRepositoryHybridImpl: Successfully synced ${calculations.length} calculations to SharedPreferences',
      );
    } catch (e) {
      print(
        'ProfileRepositoryHybridImpl: Error syncing to SharedPreferences: $e',
      );
      // Don't throw - this is a background operation that shouldn't affect the main flow
    }
  }

  // Retrieve data from SharedPreferences as fallback
  Future<List<MacroResult>> _getCalculationsFromSharedPreferences(
    String userId,
  ) async {
    try {
      print(
        'ProfileRepositoryHybridImpl: Retrieving calculations from SharedPreferences for user $userId',
      );

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      final key = 'saved_macros_$userId';

      // Get data from SharedPreferences
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        print('No data found in SharedPreferences');
        return [];
      }

      // Parse JSON data
      final jsonData = json.decode(jsonString) as List;
      final calculations =
          jsonData.map((item) {
            return MacroResult(
              id: item['id'],
              calories: (item['calories'] as num).toDouble(),
              protein: (item['protein'] as num).toDouble(),
              carbs: (item['carbs'] as num).toDouble(),
              fat: (item['fat'] as num).toDouble(),
              calculationType: item['calculationType'],
              timestamp:
                  item['timestamp'] != null
                      ? DateTime.parse(item['timestamp'])
                      : null,
              isDefault: item['isDefault'] ?? false,
              name: item['name'],
              lastModified:
                  item['lastModified'] != null
                      ? DateTime.parse(item['lastModified'])
                      : null,
              userId: item['userId'] ?? userId,
            );
          }).toList();

      print(
        'ProfileRepositoryHybridImpl: Retrieved ${calculations.length} calculations from SharedPreferences',
      );
      return calculations;
    } catch (e) {
      print(
        'ProfileRepositoryHybridImpl: Error retrieving from SharedPreferences: $e',
      );
      return [];
    }
  }

  @override
  Future<List<MacroResult>> getSavedMacros({String? userId}) async {
    final uid = _getUserId(userId);
    print('ProfileRepositoryHybridImpl: Getting saved macros for user $uid');

    try {
      // First try to get from database
      final userInfos = await syncService.getSavedUserInfos(uid);
      final results =
          userInfos
              .map((u) => MacroResult.fromUserInfo(u, explicitUserId: uid))
              .toList();

      // If we got results, sync them to SharedPreferences for backup
      if (results.isNotEmpty) {
        _syncToSharedPreferences(uid);
        return _filterAndEnsureSingleDefault(results);
      }

      // If no results from database, try SharedPreferences
      final prefsResults = await _getCalculationsFromSharedPreferences(uid);
      if (prefsResults.isNotEmpty) {
        print(
          'ProfileRepositoryHybridImpl: Using SharedPreferences fallback data',
        );
        return _filterAndEnsureSingleDefault(prefsResults);
      }

      // If still no results, return empty list
      return [];
    } catch (e) {
      print('ProfileRepositoryHybridImpl: Error getting saved macros: $e');

      // On error, try SharedPreferences
      final prefsResults = await _getCalculationsFromSharedPreferences(uid);
      if (prefsResults.isNotEmpty) {
        print(
          'ProfileRepositoryHybridImpl: Using SharedPreferences fallback data after error',
        );
        return _filterAndEnsureSingleDefault(prefsResults);
      }

      return [];
    }
  }

  // Helper method to filter out duplicates and ensure only one default macro
  List<MacroResult> _filterAndEnsureSingleDefault(List<MacroResult> macros) {
    if (macros.isEmpty) return [];

    // Use a map to track unique IDs
    final Map<String, MacroResult> uniqueMacros = {};
    MacroResult? defaultMacro;
    DateTime? latestDefaultTimestamp;

    // First pass: collect unique macros and find the latest default
    for (final macro in macros) {
      final id = macro.id;
      if (id == null) continue;

      // Store in unique map (most recent version wins)
      if (uniqueMacros.containsKey(id)) {
        final existingMacro = uniqueMacros[id]!;
        final existingTime =
            existingMacro.timestamp ??
            existingMacro.lastModified ??
            DateTime(1970);
        final newTime = macro.timestamp ?? macro.lastModified ?? DateTime(1970);

        if (newTime.isAfter(existingTime)) {
          uniqueMacros[id] = macro;
        }
      } else {
        uniqueMacros[id] = macro;
      }

      // Track the latest default macro
      if (macro.isDefault == true) {
        final macroTimestamp =
            macro.timestamp ?? macro.lastModified ?? DateTime(1970);
        if (defaultMacro == null ||
            (latestDefaultTimestamp != null &&
                macroTimestamp.isAfter(latestDefaultTimestamp))) {
          defaultMacro = macro;
          latestDefaultTimestamp = macroTimestamp;
        }
      }
    }

    // Second pass: ensure only one default
    if (defaultMacro != null) {
      // Reset all defaults
      for (final id in uniqueMacros.keys) {
        final macro = uniqueMacros[id]!;
        if (macro.isDefault == true && macro.id != defaultMacro!.id) {
          // Create a copy with isDefault set to false
          uniqueMacros[id] = macro.copyWith(isDefault: false);
        }
      }
    } else if (uniqueMacros.isNotEmpty) {
      // If no default was found, set the most recently modified one as default
      MacroResult mostRecent = uniqueMacros.values.first;
      DateTime? mostRecentTime =
          mostRecent.timestamp ?? mostRecent.lastModified;

      for (final macro in uniqueMacros.values) {
        final macroTime = macro.timestamp ?? macro.lastModified;
        if (mostRecentTime == null ||
            (macroTime != null && macroTime.isAfter(mostRecentTime))) {
          mostRecent = macro;
          mostRecentTime = macroTime;
        }
      }

      // Set the most recent as default
      uniqueMacros[mostRecent.id!] = mostRecent.copyWith(isDefault: true);
    }

    print(
      'ProfileRepositoryHybridImpl: Filtered to ${uniqueMacros.length} unique macros with one default',
    );
    return uniqueMacros.values.toList();
  }

  @override
  Future<void> saveMacro(MacroResult result, {String? userId}) async {
    final uid = _getUserId(userId);
    print('ProfileRepositoryHybridImpl: Saving macro for user $uid');

    try {
      // Save to primary storage
      final userInfo = result.toUserInfo();
      await syncService.saveUserInfo(uid, userInfo);

      // Also save to SharedPreferences as backup
      await _syncToSharedPreferences(uid);
    } catch (e) {
      print('ProfileRepositoryHybridImpl: Error saving macro: $e');

      // On error, try to save directly to SharedPreferences
      try {
        // Get existing calculations
        final prefs = await SharedPreferences.getInstance();
        final key = 'saved_macros_$uid';
        final jsonString = prefs.getString(key) ?? '[]';
        final jsonData = json.decode(jsonString) as List;

        // Add new calculation
        final newCalcJson = {
          'id': result.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'calories': result.calories,
          'protein': result.protein,
          'carbs': result.carbs,
          'fat': result.fat,
          'timestamp': DateTime.now().toIso8601String(),
          'isDefault': result.isDefault,
          'userId': uid,
          'name': result.name,
          'calculationType': result.calculationType,
          'lastModified': DateTime.now().toIso8601String(),
        };

        jsonData.add(newCalcJson);

        // Save back to SharedPreferences
        await prefs.setString(key, json.encode(jsonData));
        print(
          'ProfileRepositoryHybridImpl: Saved macro to SharedPreferences as fallback',
        );
      } catch (e2) {
        print(
          'ProfileRepositoryHybridImpl: Error saving to SharedPreferences: $e2',
        );
        // At this point we've tried everything, just rethrow
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteMacro(String id, {String? userId}) async {
    final uid = _getUserId(userId);
    print('ProfileRepositoryHybridImpl: Deleting macro $id for user $uid');
    await syncService.deleteUserInfo(uid, id);
  }

  @override
  Future<void> setDefaultMacro(String id, {required String userId}) async {
    print(
      'ProfileRepositoryHybridImpl: Setting default macro $id for user $userId',
    );
    await syncService.setDefaultUserInfo(userId, id);
  }

  @override
  Future<MacroResult?> getDefaultMacro({String? userId}) async {
    final uid = _getUserId(userId);
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print(
          'ProfileRepositoryHybridImpl: Getting default macro for user $uid (attempt ${retryCount + 1})',
        );

        // First try to get from MacroCalculationDB which has in-memory cache
        final macroResult = await _macroDB.getDefaultCalculation(userId: uid);

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
        final userInfo = await syncService.getDefaultUserInfo(uid);

        // Check if we have a complete user info that can be used for calculation
        if (userInfo != null && _isUserInfoComplete(userInfo)) {
          print('ProfileRepositoryHybridImpl: Found complete user info');
          print('ID: ${userInfo.id}, Name: ${userInfo.name}');
          print('Age: ${userInfo.age}, Sex: ${userInfo.sex}');
          print(
            'Weight: ${userInfo.weight}, Height: ${userInfo.feet}\'${userInfo.inches}"',
          );

          // Calculate macros from user info
          final macroResultFromUserInfo = MacroResult.fromUserInfo(
            userInfo,
            explicitUserId:
                uid, // Use the explicit userId to ensure correct association
          );

          // Check if the calculation produced valid values
          if (macroResultFromUserInfo.calories > 0 &&
              macroResultFromUserInfo.protein > 0) {
            print(
              'ProfileRepositoryHybridImpl: Valid calculation from user info',
            );
            print(
              'Calories: ${macroResultFromUserInfo.calories}, Protein: ${macroResultFromUserInfo.protein}',
            );

            // Save this calculation to MacroCalculationDB to update the cache
            if (macroResultFromUserInfo.id != null) {
              print(
                'ProfileRepositoryHybridImpl: Saving valid macro to MacroCalculationDB',
              );
              try {
                await _macroDB.insertCalculation(
                  macroResultFromUserInfo.copyWith(isDefault: true),
                  userId: uid,
                );
              } catch (e) {
                print('Error saving calculation to database: $e');
                // Continue even if saving fails - we still have the calculation in memory
              }
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
        final savedMacros = await getSavedMacros(userId: uid);

        // Only use macros that already exist and have valid values
        final validMacros =
            savedMacros
                .where((macro) => macro.calories > 0 && macro.protein > 0)
                .toList();

        if (validMacros.isNotEmpty) {
          // Sort by timestamp to get the most recent
          validMacros.sort((a, b) {
            final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime); // Descending order
          });

          final mostRecentValidMacro = validMacros.first;
          print('Using existing valid macro: ${mostRecentValidMacro.id}');
          _lastValidMacroResult = mostRecentValidMacro;
          return mostRecentValidMacro;
        }

        // If we've reached this point, we don't have any valid macros
        // Instead of creating a fallback, just return null
        // The UI will handle this case appropriately
        print('No valid macros found, returning null');
        return null;
      } catch (e) {
        print(
          'ProfileRepositoryHybridImpl: Error getting default macro (attempt ${retryCount + 1}): $e',
        );
        retryCount++;

        // If we've reached max retries, use fallback
        if (retryCount >= maxRetries) {
          print(
            'ProfileRepositoryHybridImpl: Max retries reached, using fallback',
          );
          break;
        }

        // Small delay before retry to allow system to stabilize
        await Future.delayed(Duration(milliseconds: 300));
      }
    }

    // Even on error, try to return the last valid result if available
    if (_lastValidMacroResult != null) {
      print(
        'ProfileRepositoryHybridImpl: Returning last valid result after error',
      );
      return _lastValidMacroResult;
    }

    // Return null instead of creating an emergency fallback
    print('ProfileRepositoryHybridImpl: No valid macro found, returning null');
    return null;
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
