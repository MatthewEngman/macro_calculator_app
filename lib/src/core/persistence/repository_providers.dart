// lib/src/core/persistence/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/profile/data/repositories/user_info_repository_sqlite_impl.dart';
import '../../features/calculator/data/repositories/calculator_repository_sqlite_impl.dart';
import '../../features/meal_plan/data/repositories/meal_plan_repository_sqlite_impl.dart';
import 'data_sync_manager.dart';

// Firebase providers
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

// Repository providers
final userInfoRepositorySQLiteProvider = Provider<UserInfoRepositorySQLiteImpl>(
  (ref) {
    final auth = ref.watch(firebaseAuthProvider);
    return UserInfoRepositorySQLiteImpl(auth);
  },
);

final calculatorRepositorySQLiteProvider =
    Provider<CalculatorRepositorySQLiteImpl>((ref) {
      final auth = ref.watch(firebaseAuthProvider);
      return CalculatorRepositorySQLiteImpl(auth);
    });

final mealPlanRepositorySQLiteProvider = Provider<MealPlanRepositorySQLiteImpl>(
  (ref) {
    final auth = ref.watch(firebaseAuthProvider);
    return MealPlanRepositorySQLiteImpl(auth);
  },
);

// Data sync manager provider
final dataSyncManagerProvider = Provider<DataSyncManager>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final connectivity = ref.watch(connectivityProvider);
  return DataSyncManager(auth, firestore, connectivity);
});
