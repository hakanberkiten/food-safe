import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../widgets/ui.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      if (_isLoginMode) {
        await widget.controller.login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );
        _statusMessage = 'Successfully logged in.';
      } else {
        await widget.controller.signup(
          email: _signupEmailController.text.trim(),
          password: _signupPasswordController.text,
          fullName: _signupNameController.text.trim().isEmpty
              ? null
              : _signupNameController.text.trim(),
        );
        _statusMessage = 'Account created successfully.';
      }
      setState(() {});
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _logout() async {
    await widget.controller.logout();
    setState(() {
      _statusMessage = 'Logged out successfully.';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          AppPanel(
            color: AppPalette.forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoginMode ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFFF8F2E8),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isLoginMode
                      ? 'Sign in to access your personalized health reports and history.'
                      : 'Join us to get AI-powered product insights tailored to your health.',
                  style: const TextStyle(color: Color(0xFFD7E7DF), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Login'),
                      icon: Icon(Icons.login_rounded),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Sign Up'),
                      icon: Icon(Icons.person_add_rounded),
                    ),
                  ],
                  selected: {_isLoginMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isLoginMode = selection.first;
                      _errorMessage = null;
                      _statusMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_isLoginMode) ...[
                  _AuthField(
                    controller: _loginEmailController,
                    label: 'Email Address',
                  ),
                  const SizedBox(height: 16),
                  _AuthField(
                    controller: _loginPasswordController,
                    label: 'Password',
                    obscureText: true,
                  ),
                ] else ...[
                  _AuthField(
                    controller: _signupNameController,
                    label: 'Full Name',
                  ),
                  const SizedBox(height: 16),
                  _AuthField(
                    controller: _signupEmailController,
                    label: 'Email Address',
                  ),
                  const SizedBox(height: 16),
                  _AuthField(
                    controller: _signupPasswordController,
                    label: 'Password',
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    _isLoginMode
                        ? Icons.login_rounded
                        : Icons.person_add_rounded,
                  ),
                  label: Text(
                    _isSubmitting
                        ? 'Connecting...'
                        : _isLoginMode
                        ? 'Sign In'
                        : 'Create Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.mint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.rose,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF3EEE5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
