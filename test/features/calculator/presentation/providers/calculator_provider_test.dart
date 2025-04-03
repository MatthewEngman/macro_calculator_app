import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:macro_masher/src/features/calculator/domain/use_cases/calculate_macros_use_case.dart';
import 'package:macro_masher/src/features/calculator/presentation/providers/calculator_provider.dart';

class MockCalculateMacrosUseCase extends Mock
    implements CalculateMacrosUseCase {}

void main() {
  late ProviderContainer container;
  late MockCalculateMacrosUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockCalculateMacrosUseCase();
    container = ProviderContainer(
      overrides: [
        calculateMacrosUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state should be null', () {
    final calculator = container.read(calculatorProvider);
    expect(calculator, isNull);
  });
}
