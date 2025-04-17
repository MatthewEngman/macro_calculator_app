import 'package:macro_masher/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import '../../../calculator/domain/entities/macro_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepositoryHybridImpl implements ProfileRepository {
  final FirestoreSyncService syncService;
  ProfileRepositoryHybridImpl(this.syncService);

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
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
      // First try to get the default user info
      final userInfo = await syncService.getDefaultUserInfo(_userId);
      if (userInfo == null) {
        print('ProfileRepositoryHybridImpl: No default user info found');
        return null;
      }

      // Log the user info for debugging
      print('ProfileRepositoryHybridImpl: Retrieved user info:');
      print('ID: ${userInfo.id}, Name: ${userInfo.name}');
      print('Age: ${userInfo.age}, Sex: ${userInfo.sex}');
      print(
        'Weight: ${userInfo.weight}, Height: ${userInfo.feet}\'${userInfo.inches}"',
      );
      print(
        'Units: ${userInfo.units}, Activity: ${userInfo.activityLevel}, Goal: ${userInfo.goal}',
      );

      // Create a macro result from the user info
      final macroResult = MacroResult.fromUserInfo(userInfo);

      // Log the calculation for debugging
      print('ProfileRepositoryHybridImpl: Created macro result from user info');
      print('User Info ID: ${userInfo.id}, Units: ${userInfo.units}');
      print(
        'Calculated Macros: ${macroResult.calories} kcal, ${macroResult.protein}g protein, ${macroResult.carbs}g carbs, ${macroResult.fat}g fat',
      );

      return macroResult;
    } catch (e) {
      print('ProfileRepositoryHybridImpl: Error getting default macro: $e');
      return null;
    }
  }
}
