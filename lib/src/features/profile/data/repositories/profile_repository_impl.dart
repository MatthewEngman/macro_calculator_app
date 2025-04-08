// lib/src/features/profile/data/repositories/profile_repository_impl.dart

import 'package:macro_masher/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../calculator/domain/entities/macro_result.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SharedPreferences _prefs;
  static const String _key = 'saved_macros';

  ProfileRepositoryImpl(this._prefs);

  @override
  Future<List<MacroResult>> getSavedMacros() async {
    final String? data = _prefs.getString(_key);
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
            timestamp: DateTime.parse(json['timestamp']),
            isDefault: json['isDefault'] ?? false,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveMacro(MacroResult result) async {
    final List<MacroResult> current = await getSavedMacros();
    final newResult = result.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
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
            },
          )
          .toList(),
    );

    await _prefs.setString(_key, data);
  }

  @override
  Future<void> deleteMacro(String id) async {
    final List<MacroResult> current = await getSavedMacros();

    // Find the macro to delete
    final macroToDeleteIndex = current.indexWhere((r) => r.id == id);

    // If macro not found or is default, don't delete
    if (macroToDeleteIndex == -1) return;
    if (current[macroToDeleteIndex].isDefault) return;

    // Remove the macro
    current.removeAt(macroToDeleteIndex);

    // Save the updated list
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
            },
          )
          .toList(),
    );

    await _prefs.setString(_key, data);
  }

  @override
  Future<void> setDefaultMacro(String id) async {
    final List<MacroResult> current = await getSavedMacros();

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
            },
          )
          .toList(),
    );

    await _prefs.setString(_key, data);
  }

  @override
  Future<MacroResult?> getDefaultMacro() async {
    final List<MacroResult> macros = await getSavedMacros();
    try {
      return macros.firstWhere((macro) => macro.isDefault);
    } catch (e) {
      // No default macro found
      return null;
    }
  }
}
