// lib/src/core/persistence/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'persistence_service.dart';

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

// FutureProvider for PersistenceService
final persistenceServiceProvider = FutureProvider<PersistenceService>((
  ref,
) async {
  // Get the database instance from DatabaseHelper
  final db = await DatabaseHelper.instance.database;
  final service = PersistenceService(db);
  // Initialize the service (it checks/creates the settings table)
  await service.initialize();
  return service;
});

// FutureProvider for LocalStorageService (awaits PersistenceService)
final localStorageServiceProvider = FutureProvider<LocalStorageService>((
  ref,
) async {
  // Await the PersistenceService provider
  final persistenceService = await ref.watch(persistenceServiceProvider.future);
  return LocalStorageService(persistenceService);
});

// FutureProvider for MealPlanRepositorySQLiteImpl (awaits LocalStorageService)
final mealPlanRepositorySQLiteProvider =
    FutureProvider<MealPlanRepositorySQLiteImpl>((ref) async {
      // Await the LocalStorageService provider
      final storageService = await ref.watch(
        localStorageServiceProvider.future,
      );
      return MealPlanRepositorySQLiteImpl(storageService);
    });

final profileRepositorySyncProvider = Provider<ProfileRepository>((ref) {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  return ProfileRepositoryHybridImpl(syncService); // CORRECT
});

// FirestoreSyncService provider
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService();
});

// Data sync manager provider
final dataSyncManagerProvider = Provider<DataSyncManager>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final connectivity = ref.watch(connectivityProvider);
  return DataSyncManager(auth, firestore, connectivity);
});
