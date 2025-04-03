import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart'; // Import sqflite if needed here, or rely on core providers
import '../../../../core/persistence/persistence_service.dart'; // Import core service
// Import database helper
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/macro_result.dart';
import '../../domain/use_cases/calculate_macros_use_case.dart';
import '../../domain/repositories/calculator_settings_repository.dart';
import '../../data/repositories/calculator_settings_repository_impl.dart'; // Import implementation

// Provider for the initialized Database instance (defined in main.dart)
final databaseProvider = Provider<Database>((ref) {
  // This will be overridden in main.dart after initialization
  throw UnimplementedError('Database provider must be overridden');
});

// Provider for the PersistenceService using the Database
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  final db = ref.watch(databaseProvider);
  return PersistenceService(db);
});

// Create a provider for the UseCase
final calculateMacrosUseCaseProvider = Provider<CalculateMacrosUseCase>((ref) {
  return CalculateMacrosUseCase();
});

// Create a provider for the Repository Implementation
// It now depends on the persistenceServiceProvider
final calculatorSettingsRepositoryProvider =
    Provider<CalculatorSettingsRepository>((ref) {
      final persistenceService = ref.watch(persistenceServiceProvider);
      return CalculatorSettingsRepositoryImpl(persistenceService);
    });

// Create a Notifier to manage the state
class CalculatorNotifier extends StateNotifier<MacroResult?> {
  final CalculateMacrosUseCase _calculateMacrosUseCase;
  final CalculatorSettingsRepository _settingsRepository;

  CalculatorNotifier(this._calculateMacrosUseCase, this._settingsRepository)
    : super(null);

  // Add state variables for the form inputs
  double weight = 0;
  int feet = 0;
  int inches = 0;
  int age = 0;
  String sex = 'male';
  String activityLevel = 'sedentary';
  String goal = 'maintain';
  double? weightChangeRate;

  // Method to calculate macros
  MacroResult? calculateMacros() {
    final input = CalculationInput(
      weight: weight,
      feet: feet,
      inches: inches,
      age: age,
      sex: sex,
      activityLevel: activityLevel,
      goal: goal,
      weightChangeRate: weightChangeRate,
    );
    final result = _calculateMacrosUseCase.execute(input);
    state = result;
    return result;
  }

  // Methods to save and load goal (loadGoal is now async)
  Future<void> saveGoal(String newGoal) async {
    goal = newGoal; // Update local state immediately for responsiveness
    await _settingsRepository.saveGoal(newGoal);
    // Optionally re-fetch or just trust the local state update
  }

  Future<void> loadGoal() async {
    final loadedGoal =
        await _settingsRepository.getGoal(); // Now returns Future<String?>
    if (loadedGoal != null) {
      goal = loadedGoal;
      // Important: Need to notify listeners if the state object itself doesn't change
      // If 'goal' was part of an immutable state object, creating a new state
      // would trigger rebuilds. Since 'goal' is a mutable field here,
      // we might need a way to force a UI update if needed, e.g., by calling
      // state = state; or managing goal within an immutable state class.
      // For simplicity here, we assume direct field mutation is sufficient
      // if the UI rebuilds based on other state changes or user interactions.
      // A more robust approach involves immutable state.
    }
    // Handle case where goal is null if necessary (e.g., set default)
  }
}

// Create a StateNotifierProvider
final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, MacroResult?>((ref) {
      final calculateMacrosUseCase = ref.watch(calculateMacrosUseCaseProvider);
      final calculatorSettingsRepository = ref.watch(
        calculatorSettingsRepositoryProvider,
      );
      return CalculatorNotifier(
        calculateMacrosUseCase,
        calculatorSettingsRepository,
      );
    });
