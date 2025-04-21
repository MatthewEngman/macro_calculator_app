// lib/src/features/profile/data/repositories/profile_repository_impl.dart

import 'package:macro_masher/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../calculator/domain/entities/macro_result.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SharedPreferences _prefs;
  static const String _key = 'saved_macros';

  ProfileRepositoryImpl(this._prefs);

  // Helper to get the key with user ID
  String _getKey(String? userId) {
    if (userId == null) return _key;
    return '${_key}_$userId';
  }

  @override
  Future<List<MacroResult>> getSavedMacros({String? userId}) async {
    final String? data = _prefs.getString(_getKey(userId));
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList
        .map(
          (json) => MacroResult(
            id: json['id'],
            calories: json['calories'],
            protein: json['protein'],
            carbs: json['carbs'],
            fat: json['fat'],
            timestamp:
                json['timestamp'] != null
                    ? DateTime.parse(json['timestamp'])
                    : null,
            isDefault: json['isDefault'] ?? false,
            userId: userId,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveMacro(MacroResult result, {String? userId}) async {
    final List<MacroResult> current = await getSavedMacros(userId: userId);
    final newResult = result.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      userId: userId,
    );
    current.add(newResult);

    final String data = json.encode(
      current
          .map(
            (r) => {
              'id': r.id,
              'calories': r.calories,
              'protein': r.protein,
              'carbs': r.carbs,
              'fat': r.fat,
              'timestamp': r.timestamp?.toIso8601String(),
              'isDefault': r.isDefault,
              'userId': r.userId,
            },
          )
          .toList(),
    );

    await _prefs.setString(_getKey(userId), data);
  }

  @override
  Future<void> deleteMacro(String id) async {
    // Since we don't know which user this macro belongs to, we need to check all
    final allKeys = _prefs.getKeys().where((key) => key.startsWith(_key));

    for (final key in allKeys) {
      final String? data = _prefs.getString(key);
      if (data == null) continue;

      final List<dynamic> jsonList = json.decode(data);
      final List<Map<String, dynamic>> updatedList = [];
      bool changed = false;

      for (final item in jsonList) {
        if (item['id'] == id && !(item['isDefault'] ?? false)) {
          changed = true;
          continue; // Skip this item (delete)
        }
        updatedList.add(Map<String, dynamic>.from(item));
      }

      if (changed) {
        await _prefs.setString(key, json.encode(updatedList));
        return; // Found and deleted
      }
    }
  }

  @override
  Future<void> setDefaultMacro(String id, {required String userId}) async {
    final List<MacroResult> current = await getSavedMacros(userId: userId);

    // Update all macros: set isDefault to false for all except the one with matching id
    final updated =
        current.map((macro) {
          return macro.copyWith(isDefault: macro.id == id);
        }).toList();

    final String data = json.encode(
      updated
          .map(
            (r) => {
              'id': r.id,
              'calories': r.calories,
              'protein': r.protein,
              'carbs': r.carbs,
              'fat': r.fat,
              'timestamp': r.timestamp?.toIso8601String(),
              'isDefault': r.isDefault,
              'userId': r.userId,
            },
          )
          .toList(),
    );

    await _prefs.setString(_getKey(userId), data);
  }

  @override
  Future<MacroResult?> getDefaultMacro({String? userId}) async {
    final List<MacroResult> macros = await getSavedMacros(userId: userId);
    try {
      return macros.firstWhere((macro) => macro.isDefault);
    } catch (e) {
      // No default macro found
      return null;
    }
  }
}
