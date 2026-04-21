import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../state/wellness_controller.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  bool _loadingRequest = false;
  bool _loadingConfirm = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _token.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request reset token',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                  'We will generate a token you can use to reset your password.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadingRequest
                    ? null
                    : () async {
                        setState(() => _loadingRequest = true);
                        final result = await ref
                            .read(wellnessControllerProvider.notifier)
                            .requestPasswordReset(email: _email.text.trim());
                        if (!mounted) return;
                        setState(() => _loadingRequest = false);
                        if (result.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.error!)),
                          );
                          return;
                        }
                        if (result.token != null) {
                          _token.text = result.token!;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reset token generated.'),
                          ),
                        );
                      },
                child: _loadingRequest
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generate token'),
              ),
              const SizedBox(height: 28),
              Text('Set new password',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Paste the token and choose a new password.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _token,
                decoration: const InputDecoration(labelText: 'Reset token'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadingConfirm
                    ? null
                    : () async {
                        setState(() => _loadingConfirm = true);
                        final error = await ref
                            .read(wellnessControllerProvider.notifier)
                            .confirmPasswordReset(
                              token: _token.text.trim(),
                              newPassword: _newPassword.text.trim(),
                            );
                        if (!mounted) return;
                        setState(() => _loadingConfirm = false);
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated. Please login.'),
                          ),
                        );
                        context.go('/login');
                      },
                child: _loadingConfirm
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update password'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
