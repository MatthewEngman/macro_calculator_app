import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macro_masher/src/core/persistence/repository_providers.dart'
    as persistence;
import 'package:macro_masher/src/core/persistence/shared_preferences_provider.dart';
import '../../../profile/domain/entities/user_info.dart'; // Assuming Goal, ActivityLevel, Units are defined here
import '../../../profile/presentation/providers/settings_provider.dart'; // Assuming sharedPreferencesProvider is defined via this import chain
import '../../../calculator/presentation/providers/calculator_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'dart:convert';

Future<void> completeOnboarding(UserInfo userInfo, WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  // Await the future to get the actual service instance
  final syncService = await ref.read(
    persistence.firestoreSyncServiceProvider.future,
  );
  final auth = ref.read(persistence.firebaseAuthProvider);
  final userId = auth.currentUser?.uid;
  if (userId != null) {
    try {
      // Try to save to database, but don't let failure block onboarding completion
      await syncService.saveUserInfo(userId, userInfo);
      print('Successfully saved user info during onboarding');
    } catch (e) {
      print('Error saving user info during onboarding: $e');
      // Continue despite database error - we'll rely on in-memory cache
    } finally {
      // Always mark onboarding as complete, even if database operations fail
      await prefs.setBool('onboarding_complete', true);
      print('Onboarding marked as complete in SharedPreferences');
    }
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  // Current step in the onboarding flow
  String _currentStep = 'welcome';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers and state variables
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;

  final _measurementsFormKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();

  // Goal and activity level
  Goal _selectedGoal = Goal.maintain;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  Units _selectedUnits = Units.imperial;

  // Weight change rate (lbs/kg per week)
  double _weightChangeRate = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _proceedToNextStep() async {
    // Original logic for proceeding (validation happens inside build methods)
    await _animationController.reverse();

    setState(() {
      switch (_currentStep) {
        case 'welcome':
          _currentStep = 'personal_info';
          break;
        case 'personal_info':
          // Validation check was originally inside the button press in _buildPersonalInfoStep
          // Proceeding here relies on that button calling this method *after* validation.
          _currentStep = 'body_measurements';
          break;
        case 'body_measurements':
          // Validation check was originally inside the button press in _buildBodyMeasurementsStep
          _currentStep = 'fitness_goals';
          break;
        case 'fitness_goals':
          _currentStep = 'activity_level';
          break;
        case 'activity_level':
          _currentStep = 'complete';
          break;
        case 'complete':
          // This case was calling _finalizeOnboarding in the original code,
          // but it's better practice for the 'Complete' button to call it.
          // Keeping original logic flow for now, but the button in
          // _buildCompletionStep also calls _finalizeOnboarding.
          // This might lead to double execution if not careful.
          // For minimal change, let's assume the button is the primary trigger.
          // _finalizeOnboarding(); // Commenting out based on original structure where button calls it
          return; // Stay on complete step until button press
      }
    });

    _animationController.forward();
  }

  Future<void> _finalizeOnboarding() async {
    if (!mounted) return;

    try {
      // Capture all provider references first
      final prefs = ref.read(sharedPreferencesProvider);
      final calculatorNotifier = ref.read(calculatorProvider.notifier);
      final profileNotifier = ref.read(profileProvider.notifier);
      final auth = ref.read(persistence.firebaseAuthProvider);
      final currentUser = auth.currentUser;

      // Check if user is authenticated (either signed in or anonymous)
      if (currentUser == null) {
        // Handle case where user is not authenticated at all
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Use Firebase UID as the user ID (works for both Google sign-in and anonymous users)
      final String userId = currentUser.uid;
      final bool isAnonymous = currentUser.isAnonymous;

      print('Onboarding: User ID: $userId (anonymous: $isAnonymous)');

      // Generate a unique ID for the user profile
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create user profile from collected data (using original defaults logic)
      final userInfo = UserInfo(
        id: uniqueId, // Add the unique ID here
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 30,
        sex: _selectedGender ?? 'male',
        weight: double.tryParse(_weightController.text) ?? 70,
        feet: int.tryParse(_heightFeetController.text) ?? 5,
        inches: int.tryParse(_heightInchesController.text) ?? 10,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
        units: _selectedUnits,
        isDefault: true, // Set as default since it's the first profile
        lastModified: DateTime.now(), // Add timestamp for conflict resolution
        weightChangeRate: _weightChangeRate, // Add weight change rate
      );

      // User is authenticated, proceed with saving
      await completeOnboarding(userInfo, ref);

      // Calculate macros
      final macroResult = calculatorNotifier.calculateMacros();

      // Save the calculated macros as the default
      if (macroResult != null) {
        // Save the macro result with a timestamp and userId
        final macroWithTimestampAndUserId = macroResult.copyWith(
          timestamp: DateTime.now(),
          userId:
              userId, // Add the Firebase user ID here (works for both Google and anonymous)
        );

        print('Saving macro with userId: $userId (anonymous: $isAnonymous)');

        // Try to save via the profile notifier (which uses the database)
        try {
          await profileNotifier.saveMacro(
            macroWithTimestampAndUserId,
            userId: userId,
          );
        } catch (e) {
          print('Error saving macro via profile notifier: $e');
          // Continue despite error - we'll save directly to SharedPreferences below
        }

        // DIRECT FALLBACK: Save the macro calculation directly to SharedPreferences
        // This ensures we have the data even if database operations fail
        try {
          final macroJson = {
            'id':
                macroWithTimestampAndUserId.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'calories': macroWithTimestampAndUserId.calories,
            'protein': macroWithTimestampAndUserId.protein,
            'carbs': macroWithTimestampAndUserId.carbs,
            'fat': macroWithTimestampAndUserId.fat,
            'timestamp':
                macroWithTimestampAndUserId.timestamp?.toIso8601String() ??
                DateTime.now().toIso8601String(),
            'isDefault': true, // Force this to be default
            'userId': userId,
            'name': 'My Macros',
            'calculationType':
                _selectedGoal == Goal.lose
                    ? 'lose'
                    : _selectedGoal == Goal.maintain
                    ? 'maintain'
                    : 'gain',
            'lastModified': DateTime.now().toIso8601String(),
          };

          // Get existing data or initialize empty list
          final String key = 'saved_macros_$userId';
          final String? existingData = prefs.getString(key);
          final List<Map<String, dynamic>> macrosList = [];

          if (existingData != null && existingData.isNotEmpty) {
            // Parse existing data
            final List<dynamic> parsed = jsonDecode(existingData);
            // Convert to list of maps and filter out any existing default macros
            macrosList.addAll(
              parsed
                  .map((item) => Map<String, dynamic>.from(item))
                  .where((item) => item['isDefault'] != true)
                  .toList(),
            );
          }

          // Add the new macro (which is set as default)
          macrosList.add(macroJson);

          // Save back to SharedPreferences
          await prefs.setString(key, jsonEncode(macrosList));
          print(
            'Successfully saved macro directly to SharedPreferences as fallback',
          );

          // Also save as default_macro for quick access
          await prefs.setString('default_macro_$userId', jsonEncode(macroJson));
          print('Saved default macro reference to SharedPreferences');
        } catch (e) {
          print('Error saving to SharedPreferences: $e');
          // Continue despite error - we've tried our best
        }

        // Reload saved macros to get the updated list with IDs
        try {
          await profileNotifier.loadSavedMacros(userId: userId);

          // Get the current state of saved macros
          final savedMacrosState = ref.read(profileProvider);

          final macrosList = savedMacrosState.value;
          if (savedMacrosState.hasValue &&
              macrosList != null &&
              macrosList.isNotEmpty) {
            // Get the most recently saved macro (should be the one we just added)
            final lastSavedMacro = macrosList.last;

            // Set it as the default if it has an ID
            if (lastSavedMacro.id != null) {
              print(
                'Setting default macro with ID: ${lastSavedMacro.id} for user: $userId (anonymous: $isAnonymous)',
              );
              try {
                await profileNotifier.setDefaultMacro(
                  lastSavedMacro.id!,
                  userId,
                );
              } catch (e) {
                print('Error setting default macro: $e');
                // Continue despite error - we've already saved it as default in SharedPreferences
              }
            }
          }
        } catch (e) {
          print('Error reloading saved macros: $e');
          // Continue despite error - we've already saved to SharedPreferences
        }
      }

      // Set the calculator values based on user profile
      calculatorNotifier.weight = userInfo.weight ?? 70;
      calculatorNotifier.feet = userInfo.feet ?? 5;
      calculatorNotifier.inches = userInfo.inches ?? 10;
      calculatorNotifier.age = userInfo.age ?? 30;
      calculatorNotifier.sex = userInfo.sex;

      // Convert activity level enum to string (original switch)
      String activityLevelString;
      switch (userInfo.activityLevel) {
        case ActivityLevel.sedentary:
          activityLevelString = 'sedentary';
          break;
        case ActivityLevel.lightlyActive:
          activityLevelString = 'lightly_active';
          break;
        case ActivityLevel.moderatelyActive:
          activityLevelString = 'moderately_active';
          break;
        case ActivityLevel.veryActive:
          activityLevelString = 'very_active';
          break;
        case ActivityLevel.extraActive:
          activityLevelString = 'extra_active';
          break;
        // Original code didn't have a default case here
      }
      calculatorNotifier.activityLevel = activityLevelString;

      // Convert goal enum to string (original switch with default)
      String goalString;
      switch (userInfo.goal) {
        case Goal.lose:
          goalString = 'lose';
          break;
        case Goal.maintain:
          goalString = 'maintain';
          break;
        case Goal.gain:
          goalString = 'gain';
          break;
      }
      calculatorNotifier.goal = goalString;

      // Save the goal for future reference
      await calculatorNotifier.saveGoal(goalString);

      // Mark onboarding as complete
      await prefs.setBool('onboarding_complete', true);
      print('Onboarding marked as complete in SharedPreferences');

      // Force refresh the providers to ensure they pick up the latest data
      ref.refresh(profileProvider);

      // Add a small delay to ensure all async operations have completed
      // This gives time for the database and SharedPreferences operations to finish
      await Future.delayed(const Duration(milliseconds: 800));

      // Explicitly refresh the defaultMacroProvider to ensure it picks up the latest data
      ref.refresh(defaultMacroProvider);

      // Check if widget is still mounted before navigating
      if (mounted) {
        // Use Future.microtask to ensure navigation happens after the current build cycle
        Future.microtask(() {
          if (mounted && context.mounted) {
            context.go('/');
          }
        });
      }
    } catch (e) {
      // Handle any errors that might occur during saving
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
      print('Error in _finalizeOnboarding: $e');
    }
  } // <<< Closing brace for _finalizeOnboarding method

  // --- Methods moved outside _finalizeOnboarding ---
  // These methods are now correctly placed within the class scope.

  String _getInstructionsForCurrentStep() {
    switch (_currentStep) {
      case 'welcome':
        return 'Welcome to Macro Masher! Let\'s set up your personalized nutrition profile.';
      case 'personal_info':
        return 'Please share some basic information about yourself.';
      case 'body_measurements':
        return 'Now, let\'s record your current body measurements.';
      case 'fitness_goals':
        return 'What are your health and fitness goals?';
      case 'activity_level':
        return 'How would you describe your typical activity level?';
      case 'complete':
        return 'Setup complete! Your personalized nutrition journey begins now.';
      default:
        return 'Please proceed with the current step.';
    }
  }

  double _getProgressValue() {
    switch (_currentStep) {
      case 'personal_info':
        return 0.2;
      case 'body_measurements':
        return 0.4;
      case 'fitness_goals':
        return 0.6;
      case 'activity_level':
        return 0.8;
      case 'complete':
        return 1.0;
      default: // Includes 'welcome'
        return 0.0;
    }
  }

  Widget _buildPersonalInfoStep() {
    return Form(
      key: _personalInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Sex',
              prefixIcon: Icon(Icons.people),
            ),
            value: _selectedGender,
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your sex';
              }
              return null;
            },
          ),
          const SizedBox(height: 48),
          Center(
            child: FilledButton(
              onPressed: () {
                // Original validation logic placement
                if (_personalInfoFormKey.currentState!.validate()) {
                  _proceedToNextStep();
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMeasurementsStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _measurementsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Units toggle
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Measurement Units', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<Units>(
                          title: const Text('Imperial (lb, ft/in)'),
                          value: Units.imperial,
                          groupValue: _selectedUnits,
                          onChanged: (Units? value) {
                            if (value != null) {
                              setState(() {
                                _selectedUnits = value;
                                // Convert values if needed
                                if (_weightController.text.isNotEmpty) {
                                  try {
                                    final double? weight = double.tryParse(
                                      _weightController.text,
                                    );
                                    if (weight != null) {
                                      // Convert kg to lbs
                                      _weightController.text =
                                          (weight * 2.20462).toStringAsFixed(1);
                                    }
                                  } catch (_) {}
                                }
                              });
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<Units>(
                          title: const Text('Metric (kg, m/cm)'),
                          value: Units.metric,
                          groupValue: _selectedUnits,
                          onChanged: (Units? value) {
                            if (value != null) {
                              setState(() {
                                _selectedUnits = value;
                                // Convert values if needed
                                if (_weightController.text.isNotEmpty) {
                                  try {
                                    final double? weight = double.tryParse(
                                      _weightController.text,
                                    );
                                    if (weight != null) {
                                      // Convert lbs to kg
                                      _weightController.text =
                                          (weight / 2.20462).toStringAsFixed(1);
                                    }
                                  } catch (_) {}
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Weight field
          TextFormField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText:
                  _selectedUnits == Units.imperial
                      ? 'Weight (lbs)'
                      : 'Weight (kg)',
              prefixIcon: const Icon(Icons.monitor_weight),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your weight';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Height fields
          if (_selectedUnits == Units.imperial)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightFeetController,
                    decoration: const InputDecoration(
                      labelText: 'Height (feet)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightInchesController,
                    decoration: const InputDecoration(labelText: 'Inches'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final inches = int.tryParse(value);
                      if (inches == null || inches < 0 || inches > 11) {
                        return 'Invalid (0-11)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightFeetController,
                    decoration: const InputDecoration(
                      labelText: 'Height (meters)',
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heightInchesController,
                    decoration: const InputDecoration(labelText: 'Centimeters'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final cm = int.tryParse(value);
                      if (cm == null || cm < 0 || cm > 99) {
                        return 'Invalid (0-99)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 48),
          Center(
            child: FilledButton(
              onPressed: () {
                if (_measurementsFormKey.currentState!.validate()) {
                  _proceedToNextStep();
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessGoalsStep() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is your primary fitness goal?', style: textTheme.titleLarge),
        const SizedBox(height: 24),
        _buildGoalOption(
          goal: Goal.lose,
          title: 'Lose Weight',
          icon: Icons.trending_down,
          description: 'Reduce body fat while preserving muscle mass',
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.maintain,
          title: 'Maintain Weight',
          icon: Icons.balance,
          description: 'Maintain current weight and body composition',
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.gain,
          title: 'Gain Muscle',
          icon: Icons.trending_up,
          description: 'Build muscle mass with minimal fat gain',
        ),

        // Only show weight change rate for lose/gain goals
        if (_selectedGoal != Goal.maintain)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedGoal == Goal.lose
                            ? 'How quickly do you want to lose weight?'
                            : 'How quickly do you want to gain weight?',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A moderate pace of ${_selectedUnits == Units.imperial ? '1-2 pounds' : '0.5-1 kg'} per week is generally recommended for sustainable results.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _weightChangeRate,
                        min: 0.5,
                        max: 2.0,
                        divisions: 3,
                        label:
                            '${_weightChangeRate.toStringAsFixed(1)} ${_selectedUnits == Units.imperial ? 'lbs' : 'kg'}/week',
                        onChanged: (value) {
                          setState(() {
                            _weightChangeRate = value;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gradual', style: textTheme.bodySmall),
                          Text('Moderate', style: textTheme.bodySmall),
                          Text('Aggressive', style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 48),
        Center(
          child: FilledButton(
            onPressed: _proceedToNextStep,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  // Helper for goal options (was correctly placed in original relative to others)
  Widget _buildGoalOption({
    required Goal goal,
    required String title,
    required IconData icon,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedGoal == goal;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? colorScheme
                          .primary // Original color logic
                      : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      // Original TextStyle
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      // Original TextStyle
                      fontSize: 12,
                      color:
                          isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelStep() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How active are you on a typical day?',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        // Original list of options (did not include extraActive UI)
        _buildActivityOption(
          level: ActivityLevel.sedentary,
          title: 'Sedentary',
          description: 'Little to no exercise, desk job',
          icon: Icons.weekend,
        ),
        const SizedBox(height: 12),
        _buildActivityOption(
          level: ActivityLevel.lightlyActive,
          title: 'Lightly Active',
          description: 'Light exercise 1-3 days per week',
          icon: Icons.directions_walk,
        ),
        const SizedBox(height: 12),
        _buildActivityOption(
          level: ActivityLevel.moderatelyActive,
          title: 'Moderately Active',
          description: 'Moderate exercise 3-5 days per week',
          icon: Icons.directions_run,
        ),
        const SizedBox(height: 12),
        _buildActivityOption(
          level: ActivityLevel.veryActive,
          title: 'Very Active',
          description: 'Hard exercise 6-7 days per week',
          icon: Icons.fitness_center,
        ),
        // Note: Original code did not have a UI element for extraActive
        const SizedBox(height: 48),
        Center(
          child: FilledButton(
            onPressed: _proceedToNextStep, // No form validation on this step
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  // Helper for activity options (was correctly placed in original relative to others)
  Widget _buildActivityOption({
    required ActivityLevel level,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedActivityLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedActivityLevel = level;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? colorScheme
                          .primary // Original color logic
                      : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      // Original TextStyle
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      // Original TextStyle
                      fontSize: 12,
                      color:
                          isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(Icons.check_circle, size: 100, color: colorScheme.primary),
        const SizedBox(height: 32),
        Text(
          'You\'re all set!',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your profile has been created and your macro targets are ready.',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        FilledButton(
          onPressed: _finalizeOnboarding, // Button triggers final action
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          child: const Text('Go to Dashboard'),
        ),
      ],
    );
  }

  Widget _buildWelcomeStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      // Original alignment
      children: [
        Icon(Icons.fitness_center, size: 100, color: colorScheme.primary),
        const SizedBox(height: 32),
        Text(
          'Macro Masher',
          style: textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your personalized nutrition assistant',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Text(
          'We\'ll help you calculate your ideal macros and generate meal plans tailored to your goals.',
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 64),
        FilledButton(
          onPressed: _proceedToNextStep, // No validation needed
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          ),
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  // --- Main Build Method ---
  Widget _buildContentForCurrentStep() {
    switch (_currentStep) {
      case 'welcome':
        return _buildWelcomeStep();
      case 'personal_info':
        return _buildPersonalInfoStep();
      case 'body_measurements':
        return _buildBodyMeasurementsStep();
      case 'fitness_goals':
        return _buildFitnessGoalsStep();
      case 'activity_level':
        return _buildActivityLevelStep();
      case 'complete':
        return _buildCompletionStep();
      default:
        return const SizedBox.shrink(); // Original fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Macro Masher'), // Original title
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            // Original FadeTransition
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator (Original placement and condition)
                if (_currentStep != 'welcome' && _currentStep != 'complete')
                  LinearProgressIndicator(
                    value: _getProgressValue(),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                  ),
                const SizedBox(height: 24), // Original spacing
                // Instructions (Original placement)
                Text(
                  _getInstructionsForCurrentStep(),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32), // Original spacing
                // Content based on current step
                Expanded(
                  child: SingleChildScrollView(
                    // Added SingleChildScrollView for safety, wasn't in original but good practice
                    child: _buildContentForCurrentStep(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
