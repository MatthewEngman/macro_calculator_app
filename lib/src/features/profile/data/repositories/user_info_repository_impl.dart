import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/user_info_respository.dart';
import '../../domain/entities/user_info.dart';

class UserInfoRepositoryImpl implements UserInfoRepository {
  final SharedPreferences _prefs;
  static const String _key = 'saved_user_infos';

  UserInfoRepositoryImpl(this._prefs);

  @override
  Future<List<UserInfo>> getSavedUserInfos() async {
    final String? data = _prefs.getString(_key);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((json) => UserInfo.fromJson(json)).toList();
  }

  @override
  Future<void> saveUserInfo(UserInfo userInfo) async {
    final List<UserInfo> current = await getSavedUserInfos();
    final newUserInfo = userInfo.copyWith(
      id: userInfo.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // If this is the first user info, set it as default
    final isFirstUserInfo = current.isEmpty;

    // Check if we're updating an existing user info
    final existingIndex = current.indexWhere(
      (info) => info.id == newUserInfo.id,
    );

    if (existingIndex >= 0) {
      // Update existing user info
      current[existingIndex] = newUserInfo;
    } else {
      // Add new user info
      current.add(newUserInfo.copyWith(isDefault: isFirstUserInfo));
    }

    final String data = json.encode(current.map((r) => r.toJson()).toList());

    await _prefs.setString(_key, data);
  }

  @override
  Future<void> deleteUserInfo(String id) async {
    final List<UserInfo> current = await getSavedUserInfos();

    // Find the user info to delete
    final userInfoToDeleteIndex = current.indexWhere((r) => r.id == id);

    // If user info not found or is default, don't delete
    if (userInfoToDeleteIndex == -1) return;
    if (current[userInfoToDeleteIndex].isDefault) return;

    // Remove the user info
    current.removeAt(userInfoToDeleteIndex);

    // Save the updated list
    final String data = json.encode(current.map((r) => r.toJson()).toList());

    await _prefs.setString(_key, data);
  }

  @override
  Future<void> setDefaultUserInfo(String id) async {
    final List<UserInfo> current = await getSavedUserInfos();

    // Update all user infos: set isDefault to false for all except the one with matching id
    final updated =
        current.map((userInfo) {
          return userInfo.copyWith(isDefault: userInfo.id == id);
        }).toList();

    final String data = json.encode(updated.map((r) => r.toJson()).toList());

    await _prefs.setString(_key, data);
  }

  @override
  Future<UserInfo?> getDefaultUserInfo() async {
    final List<UserInfo> userInfos = await getSavedUserInfos();
    try {
      return userInfos.firstWhere((userInfo) => userInfo.isDefault);
    } catch (e) {
      // No default user info found
      return userInfos.isNotEmpty ? userInfos.first : null;
    }
  }
}
