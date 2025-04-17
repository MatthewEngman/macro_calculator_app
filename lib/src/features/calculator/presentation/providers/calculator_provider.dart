import 'package:riverpod/riverpod.dart';
import '../../../../core/persistence/persistence_service.dart';
import '../../../../core/persistence/database_provider.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../domain/entities/calculation_input.dart';
import '../../domain/entities/macro_result.dart';
import '../../domain/use_cases/calculate_macros_use_case.dart';
import '../../domain/repositories/calculator_settings_repository.dart';
import '../../data/repositories/calculator_settings_repository_impl.dart';

// Provider for the PersistenceService using the Database
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  final db = ref.watch(databaseProvider);
  return PersistenceService(db);
});

// Provider for the UseCase
final calculateMacrosUseCaseProvider = Provider<CalculateMacrosUseCase>((ref) {
  return CalculateMacrosUseCase();
});

// Provider for the Repository Implementation
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
  final Ref _ref;

  CalculatorNotifier(
    this._calculateMacrosUseCase,
    this._settingsRepository,
    this._ref,
  ) : super(null);

  // Add state variables for the form inputs
  double weight = 0;
  int feet = 0;
  int inches = 0;
  int age = 0;
  String sex = 'male';
  String activityLevel = 'sedentary';
  String goal = 'maintain';
  double? weightChangeRate;

  // Convert units if needed
  double _convertWeight(double weight, Units units) {
    return units == Units.metric
        ? weight * 2.20462
        : weight; // Convert kg to lbs if metric
  }

  // Method to calculate macros
  MacroResult? calculateMacros() {
    // Get current units from settings provider
    final units = _ref.read(settingsProvider).units;

    // Convert weight to lbs if using metric
    final weightInLbs = _convertWeight(weight, units);

    final input = CalculationInput(
      weight: weightInLbs,
      feet: feet,
      inches: inches,
      age: age,
      sex: sex,
      activityLevel: activityLevel,
      goal: goal,
      weightChangeRate:
          weightChangeRate != null
              ? _convertWeight(weightChangeRate!, units)
              : null,
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
        ref,
      );
    });
