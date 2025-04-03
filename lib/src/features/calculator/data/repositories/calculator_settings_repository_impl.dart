// No changes needed here, as it depends on the PersistenceService abstraction
import '../../../../core/persistence/persistence_service.dart'; // Import the core service
import '../../domain/repositories/calculator_settings_repository.dart';

class CalculatorSettingsRepositoryImpl implements CalculatorSettingsRepository {
  final PersistenceService persistenceService;

  CalculatorSettingsRepositoryImpl(this.persistenceService);

  @override
  Future<String?> getGoal() async {
    // The underlying service method now returns Future<String?>
    return await persistenceService.getData('goal');
  }

  @override
  Future<void> saveGoal(String goal) async {
    await persistenceService.saveData('goal', goal);
  }
//Implement other methods
}