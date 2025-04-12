// lib/src/core/persistence/background_sync_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'repository_providers.dart';

class BackgroundSyncService {
  final Ref _ref;
  Timer? _syncTimer;
  StreamSubscription<User?>? _authStateSubscription;

  BackgroundSyncService(this._ref) {
    // Listen to auth state changes
    _authStateSubscription = _ref
        .read(firebaseAuthProvider)
        .authStateChanges()
        .listen(_handleAuthStateChange);

    // Start periodic sync if user is logged in
    if (_ref.read(firebaseAuthProvider).currentUser != null) {
      _startPeriodicSync();
    }
  }

  void _handleAuthStateChange(User? user) {
    if (user != null) {
      // User logged in, start sync
      _startPeriodicSync();
      // Also perform an immediate sync
      _performSync();
    } else {
      // User logged out, stop sync
      _stopPeriodicSync();
    }
  }

  void _startPeriodicSync() {
    // Stop any existing timer
    _stopPeriodicSync();

    // Sync every 15 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _performSync();
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _performSync() async {
    try {
      await _ref.read(dataSyncManagerProvider).syncAllData();
      debugPrint('Background sync completed successfully');
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  // Call this method to manually trigger a sync
  Future<void> syncNow() async {
    return _performSync();
  }

  // Call this method when disposing the service
  void dispose() {
    _stopPeriodicSync();
    _authStateSubscription?.cancel();
  }
}

// Provider for the background sync service
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final service = BackgroundSyncService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
