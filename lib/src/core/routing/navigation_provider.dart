// lib/src/core/routing/navigation_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';

/// Provider for navigation functions.
/// This provider is overridden in main.dart with the actual navigation implementation.
final navigationProvider = Provider<void Function(String)>((ref) {
  throw UnimplementedError('navigationProvider has not been initialized');
});

/// Provider that exposes the GoRouter instance.
final goRouterProvider = Provider<GoRouter>((ref) {
  return appRouter;
});
