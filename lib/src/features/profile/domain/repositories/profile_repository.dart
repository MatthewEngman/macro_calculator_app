import '../../../calculator/domain/entities/macro_result.dart';

abstract class ProfileRepository {
  Future<List<MacroResult>> getSavedMacros();
  Future<void> saveMacro(MacroResult result);
  Future<void> deleteMacro(String id);
}
