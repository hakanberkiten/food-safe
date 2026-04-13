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
      await widget.controller.setBackendUrl(widget.controller.backendUrl);
      if (_isLoginMode) {
        await widget.controller.login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );
        _statusMessage = 'Giris basarili.';
      } else {
        await widget.controller.signup(
          email: _signupEmailController.text.trim(),
          password: _signupPasswordController.text,
          fullName: _signupNameController.text.trim().isEmpty
              ? null
              : _signupNameController.text.trim(),
        );
        _statusMessage = 'Kayit tamamlandi ve token alindi.';
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
      _statusMessage = 'Cikis yapildi.';
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppPanel(
          color: AppPalette.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auth endpointlerini bagla ve oturum durumunu yonet.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu ekran /api/auth/signup ve /api/auth/login endpointlerini kullanir. Gecmis ve kaydedilen urunler sayfalari token oldugunda aktiflesir.',
                style: TextStyle(color: Color(0xFFD7E7DF), height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: 620,
              child: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          label: Text('Signup'),
                          icon: Icon(Icons.person_add_alt_1_rounded),
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
                    const SizedBox(height: 20),
                    if (_isLoginMode) ...[
                      _AuthField(
                        controller: _loginEmailController,
                        label: 'Email',
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _loginPasswordController,
                        label: 'Password',
                        obscureText: true,
                      ),
                    ] else ...[
                      _AuthField(
                        controller: _signupNameController,
                        label: 'Full name',
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _signupEmailController,
                        label: 'Email',
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _signupPasswordController,
                        label: 'Password',
                        obscureText: true,
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: Icon(
                        _isLoginMode
                            ? Icons.login_rounded
                            : Icons.person_add_alt_1_rounded,
                      ),
                      label: Text(
                        _isSubmitting
                            ? 'Islem suruyor...'
                            : _isLoginMode
                            ? 'Login'
                            : 'Signup',
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage!,
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
                        style: const TextStyle(
                          color: AppPalette.rose,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 440,
              child: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current auth state',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    StatusBadge(
                      label: widget.controller.isAuthenticated
                          ? 'SIGNED_IN'
                          : 'ANONYMOUS',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.controller.isAuthenticated
                          ? 'Current email: ${widget.controller.currentEmail}'
                          : 'History and saved products endpoints require login.',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (widget.controller.isAuthenticated)
                      FilledButton.icon(
                        onPressed: _logout,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.rose,
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Logout'),
                      )
                    else
                      const Text(
                        'Anonim modda analiz ve profil yine calisir. Token sadece kullaniciya ait gecmis ve saved listeleri acar.',
                        style: TextStyle(color: AppPalette.muted, height: 1.6),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
