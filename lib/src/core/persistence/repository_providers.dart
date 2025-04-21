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
      return CalculatorRepositorySQLiteImpl(
        auth,
        ref.watch(macroCalculationDBProvider),
      );
    });

// Provider for PersistenceService (Still needed if other parts of the app use it directly)
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  final db = ref.watch(db_provider_impl.databaseProvider);
  print(
    'repository_providers: persistenceServiceProvider watching db hash: ${db.hashCode}',
  );
  if (db == null) {
    throw Exception('Database not initialized for PersistenceService');
  }
  // Initialize PersistenceService, assuming its constructor takes Database
  // If PersistenceService doesn't need the db directly anymore, adjust this.
  // Assuming PersistenceService constructor was PersistenceService(this.database)
  return PersistenceService(db)
    ..initialize(); // Ensure initialization logic is handled
});

// Provider for UserDB - NEW
final userDBProvider = Provider<UserDB>((ref) {
  final db = ref.watch(db_provider_impl.databaseProvider);
  if (db == null) {
    throw Exception('Database not initialized for UserDB');
  }
  return UserDB(database: db);
});

// Provider for LocalStorageService - UPDATED
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  // Watch the databaseProvider directly
  final db = ref.watch(db_provider_impl.databaseProvider);
  print(
    'repository_providers: localStorageServiceProvider watching db hash: ${db.hashCode}',
  );
  if (db == null) {
    throw Exception('Database not initialized for LocalStorageService');
  }
  // Watch the new UserDB provider
  final userDB = ref.watch(userDBProvider);
  // Instantiate LocalStorageService with the Database instance and UserDB instance
  return LocalStorageService(userDB, db);
});

// Provider for MealPlanDB - NEW
final mealPlanDBProvider = Provider<MealPlanDB>((ref) {
  final db = ref.watch(db_provider_impl.databaseProvider);
  if (db == null) {
    throw Exception('Database not initialized for MealPlanDB');
  }
  return MealPlanDB(database: db);
});

// Provider for MacroCalculationDB - NEW
final macroCalculationDBProvider = Provider<MacroCalculationDB>((ref) {
  final db = ref.watch(db_provider_impl.databaseProvider);
  if (db == null) {
    throw Exception('Database not initialized for MacroCalculationDB');
  }
  return MacroCalculationDB(database: db);
});

// Provider for MealPlanRepositorySQLiteImpl (awaits LocalStorageService)
final mealPlanRepositorySQLiteProvider = Provider<MealPlanRepositorySQLiteImpl>(
  (ref) {
    // Await the LocalStorageService provider
    final storageService = ref.watch(localStorageServiceProvider);
    // Watch the MealPlanDB provider
    final mealPlanDB = ref.watch(mealPlanDBProvider);
    // Watch the UserDB provider
    final userDB = ref.watch(userDBProvider);
    // Pass all three dependencies to the constructor
    return MealPlanRepositorySQLiteImpl(storageService, mealPlanDB, userDB);
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
