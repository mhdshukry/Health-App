import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/wellness_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();
  final _gender = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _age.dispose();
    _gender.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text('Create account',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Start tracking your health with a complete profile.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                _field(_name, 'Full name', hint: 'e.g., Alex Carter'),
                const SizedBox(height: 12),
                _field(_email, 'Email', email: true, hint: 'name@email.com'),
                const SizedBox(height: 12),
                _field(_password, 'Password',
                    obscure: true, hint: 'At least 6 characters'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field(_age, 'Age', number: true, hint: '24')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_gender, 'Gender', hint: 'Male/Female')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _field(_height, 'Height (cm)',
                            number: true, hint: '175')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_weight, 'Weight (kg)',
                            number: true, hint: '70')),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          // Guard against invalid number input so we can show a friendly message.
                          late int age;
                          late double height;
                          late double weight;
                          try {
                            age = int.parse(_age.text.trim());
                            height = double.parse(_height.text.trim());
                            weight = double.parse(_weight.text.trim());
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter valid numbers.')),
                            );
                            return;
                          }

                          setState(() => _submitting = true);

                          final error = await ref
                              .read(wellnessControllerProvider.notifier)
                              .register(
                                name: _name.text.trim(),
                                email: _email.text.trim(),
                                password: _password.text.trim(),
                                age: age,
                                gender: _gender.text.trim(),
                                height: height,
                                weight: weight,
                              );

                          if (!mounted) return;

                          setState(() => _submitting = false);

                          if (error != null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }

                          context.go('/home');
                        },
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool email = false,
      bool number = false,
      bool obscure = false,
      String? hint}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: email
          ? TextInputType.emailAddress
          : (number ? TextInputType.number : TextInputType.text),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        if (email && !value.contains('@')) return 'Enter a valid email';
        if (obscure && value.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }
}
