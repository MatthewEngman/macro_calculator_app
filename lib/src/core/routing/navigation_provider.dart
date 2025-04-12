// lib/src/core/routing/navigation_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for navigation functions.
/// This provider is overridden in main.dart with the actual navigation implementation.
final navigationProvider = Provider<void Function(String)>((ref) {
  throw UnimplementedError('navigationProvider has not been initialized');
});
