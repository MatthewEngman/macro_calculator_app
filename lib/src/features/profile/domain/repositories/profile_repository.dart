import '../../../calculator/domain/entities/macro_result.dart';

abstract class ProfileRepository {
  Future<List<MacroResult>> getSavedMacros({String? userId});
  Future<void> saveMacro(MacroResult result, {String? userId});
  Future<void> deleteMacro(String id);
  Future<void> setDefaultMacro(String id, {required String userId});
  Future<MacroResult?> getDefaultMacro({String? userId});
}
