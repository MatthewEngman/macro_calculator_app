import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../widgets/saved_macro_card.dart';
import '../widgets/calculation_inputs.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          centerTitle: true,
          backgroundColor: colorScheme.surfaceContainerHighest,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Saved Results'),
              Tab(icon: Icon(Icons.settings), text: 'Calculation Settings'),
            ],
          ),
        ),
        backgroundColor: colorScheme.surface,
        body: TabBarView(
          children: [_SavedResultsTab(), const CalculationInputs()],
        ),
      ),
    );
  }
}

class _SavedResultsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macros = ref.watch(profileProvider);

    return macros.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(
              'No saved results yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final macro = data[index];
            return Dismissible(
              key: Key(macro.id ?? ''),
              onDismissed: (_) {
                if (macro.id != null) {
                  ref.read(profileProvider.notifier).deleteMacro(macro.id!);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SavedMacroCard(macro: macro),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
