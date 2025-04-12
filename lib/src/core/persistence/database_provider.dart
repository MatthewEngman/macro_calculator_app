// lib/src/core/persistence/database_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Provider for the SQLite database instance.
/// This provider is overridden in main.dart with the initialized database.
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('databaseProvider has not been initialized');
});
