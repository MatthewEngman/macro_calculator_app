// lib/src/core/persistence/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_masher/src/core/persistence/database_provider.dart'
    as db_provider_impl;
import 'package:macro_masher/src/core/persistence/firestore_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:macro_masher/src/features/profile/data/repositories/profile_repository_hybrid_impl.dart';
import 'package:macro_masher/src/features/profile/domain/repositories/profile_repository.dart';
import '../../features/calculator/data/repositories/calculator_repository_sqlite_impl.dart';
import '../../features/meal_plan/data/repositories/meal_plan_repository_sqlite_impl.dart';
import 'data_sync_manager.dart';
import 'local_storage_service.dart';
import 'persistence_service.dart';
import 'package:macro_masher/src/features/meal_plan/data/meal_plan_db.dart';
import 'package:macro_masher/src/features/profile/data/repositories/user_db.dart';
import 'package:macro_masher/src/features/calculator/data/repositories/macro_calculation_db.dart';

// Firebase providers
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

// Repository providers

final calculatorRepositorySQLiteProvider =
    Provider<CalculatorRepositorySQLiteImpl>((ref) {
      final auth = ref.watch(firebaseAuthProvider);
      return CalculatorRepositorySQLiteImpl(auth);
    });

// Provider for PersistenceService (Still needed if other parts of the app use it directly)
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  // PersistenceService no longer needs a direct database reference
  // It will get the database dynamically using DatabaseHelper.getInstance()
  return PersistenceService()
    ..initialize(); // Ensure initialization logic is handled
});

// Provider for UserDB - UPDATED
final userDBProvider = Provider<UserDB>((ref) {
  return UserDB();
});

// Provider for LocalStorageService - UPDATED
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  // Watch the UserDB provider
  final userDB = ref.watch(userDBProvider);
  // Instantiate LocalStorageService with just the UserDB instance
  return LocalStorageService(userDB);
});

// Provider for MealPlanDB - UPDATED
final mealPlanDBProvider = Provider<MealPlanDB>((ref) {
  return MealPlanDB();
});

// Provider for MacroCalculationDB - UPDATED
final macroCalculationDBProvider = Provider<MacroCalculationDB>((ref) {
  return MacroCalculationDB();
});

// Provider for MealPlanRepositorySQLiteImpl (awaits LocalStorageService)
final mealPlanRepositorySQLiteProvider = Provider<MealPlanRepositorySQLiteImpl>(
  (ref) {
    // Watch the MealPlanDB provider
    final mealPlanDB = ref.watch(mealPlanDBProvider);
    // Watch the UserDB provider
    final userDB = ref.watch(userDBProvider);
    // Pass all three dependencies to the constructor
    return MealPlanRepositorySQLiteImpl(mealPlanDB, userDB);
  },
);

final profileRepositorySyncProvider = FutureProvider<ProfileRepository>((
  ref,
) async {
  // Await the future to get the actual FirestoreSyncService instance
  final syncService = await ref.watch(firestoreSyncServiceProvider.future);
  return ProfileRepositoryHybridImpl(
    syncService,
  ); // Now passing the correct type
});

// FirestoreSyncService provider - Now depends on firestore and localStorageService
final firestoreSyncServiceProvider = FutureProvider<FirestoreSyncService>((
  ref,
) async {
  final firestore = ref.watch(
    firestoreProvider,
  ); // Keep watching firestore if needed elsewhere, though not passed here.
  // Await the localStorageService future provider
  final localStorageService = ref.watch(localStorageServiceProvider);

  // Initialize the FirestoreSyncService singleton with the dependency
  await FirestoreSyncService.initialize(localStorageService);

  // Return the singleton instance using the factory constructor
  return FirestoreSyncService();
});

// Data sync manager provider
final dataSyncManagerProvider = Provider<DataSyncManager>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final connectivity = ref.watch(connectivityProvider);
  // Watch the UserDB provider
  final userDB = ref.watch(userDBProvider);
  // Watch the MacroCalculationDB provider
  final macroDB = ref.watch(macroCalculationDBProvider);
  // Watch the MealPlanDB provider
  final mealPlanDB = ref.watch(mealPlanDBProvider);
  // Pass all dependencies to the constructor
  return DataSyncManager(
    auth,
    firestore,
    connectivity,
    userDB,
    macroDB,
    mealPlanDB,
  );
});

// Combined provider for repositories needing DataSyncManager (if any)
