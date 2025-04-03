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
            },
          )
          .toList(),
    );

    await _prefs.setString(_key, data);
  }

  @override
  Future<void> deleteMacro(String id) async {
    final List<MacroResult> current = await getSavedMacros();
    current.removeWhere((r) => r.id == id);

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
            },
          )
          .toList(),
    );

    await _prefs.setString(_key, data);
  }
}
