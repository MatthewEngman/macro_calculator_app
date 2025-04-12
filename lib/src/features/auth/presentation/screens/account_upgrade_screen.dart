import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AccountUpgradeScreen extends ConsumerStatefulWidget {
  const AccountUpgradeScreen({super.key});

  @override
  ConsumerState<AccountUpgradeScreen> createState() =>
      _AccountUpgradeScreenState();
}

class _AccountUpgradeScreenState extends ConsumerState<AccountUpgradeScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _upgradeWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the linkAnonymousAccountWithGoogle method to upgrade the account
      final userCredential =
          await ref
              .read(authRepositoryProvider)
              .linkAnonymousAccountWithGoogle();

      // If userCredential is null, the user canceled the sign-in
      if (userCredential == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account upgraded successfully!',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            width: 280,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to the profile screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Account upgrade failed: ${e.toString()}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!, textAlign: TextAlign.center),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            width: 280,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Your Account'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon at the top
              Icon(
                Icons.security_update_good,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Secure Your Data',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Upgrade Your Account?',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Keep your data when you reinstall the app',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Access your data across multiple devices',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Secure backup of all your macros and meal plans',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Google Sign-In button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                    onPressed: _upgradeWithGoogle,
                    icon: Icon(
                      Icons.g_mobiledata,
                      size: 24.0,
                      color: Colors.blue,
                    ),
                    label: const Text(
                      'Upgrade with Google',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black87,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          Navigator.of(context).pop();
                        },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: textTheme.titleMedium,
                ),
                child: const Text('Not Now'),
              ),

              const SizedBox(height: 24),

              // Note about privacy
              Text(
                'Your data will be securely stored with your Google account. We only access the information needed to identify your account.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
