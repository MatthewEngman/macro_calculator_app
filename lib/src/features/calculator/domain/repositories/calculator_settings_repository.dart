abstract class CalculatorSettingsRepository {
  Future<void> saveGoal(String goal);
  Future<String?> getGoal(); // Return type remains Future<String?>
// Add methods for other settings
}