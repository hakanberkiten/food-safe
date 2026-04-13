import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _specialController;
  late bool _lastAuthState;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _allergiesController = TextEditingController();
    _conditionsController = TextEditingController();
    _specialController = TextEditingController();
    _lastAuthState = widget.controller.isAuthenticated;
    widget.controller.addListener(_handleControllerChange);
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      _lastAuthState = widget.controller.isAuthenticated;
      widget.controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _allergiesController.dispose();
    _conditionsController.dispose();
    _specialController.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final authState = widget.controller.isAuthenticated;
    if (_lastAuthState == authState) {
      return;
    }
    _lastAuthState = authState;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final profile = await widget.controller.loadProfile();
      _allergiesController.text = profile.allergies.join(', ');
      _conditionsController.text = profile.conditions.join(', ');
      _specialController.text = profile.special.join(', ');
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final payload = UserProfileData(
        allergies: _splitValues(_allergiesController.text),
        conditions: _splitValues(_conditionsController.text),
        special: _splitValues(_specialController.text),
        sessionId: widget.controller.isAuthenticated
            ? null
            : widget.controller.sessionId,
      );
      await widget.controller.saveProfile(payload);
      setState(() {
        _statusMessage = 'Profil kaydedildi.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
                'Saglik profilini guncelle, reasoning katmanini kisisellestir.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.controller.isAuthenticated
                    ? 'Bu sayfa /api/profile/ endpointine token ile bagli.'
                    : 'Su anda anonim session ile calisiyorsun. Profil verin session_id uzerinden kaydolacak.',
                style: const TextStyle(color: Color(0xFFD7E7DF), height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          const AppPanel(child: Center(child: CircularProgressIndicator()))
        else
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              SizedBox(
                width: 640,
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile fields',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _ProfileField(
                        controller: _allergiesController,
                        label: 'Allergies',
                        hint: 'gluten, soy, peanut, lactose',
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        controller: _conditionsController,
                        label: 'Conditions',
                        hint: 'celiac, hypertension, diabetes, IBS',
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        controller: _specialController,
                        label: 'Special contexts',
                        hint: 'pregnant, child, low sodium, athlete',
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              _isSaving ? 'Kaydediliyor...' : 'Profili Kaydet',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _loadProfile,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Yeniden Yukle'),
                          ),
                        ],
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
                width: 420,
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How this is used',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Profile alanlari reasoning asamasinda allergen, gluten, sodyum ve benzeri sinyallerle esitlestirilir. Boylece ayni urun farkli kullanicilar icin farkli bir caution seviyesine cikabilir.',
                        style: TextStyle(color: AppPalette.muted, height: 1.6),
                      ),
                      const SizedBox(height: 18),
                      TagPill(
                        label: widget.controller.isAuthenticated
                            ? 'Token-bound profile'
                            : 'Session-bound profile',
                        color: widget.controller.isAuthenticated
                            ? const Color(0xFFD8E9E1)
                            : const Color(0xFFF5E4D9),
                        textColor: widget.controller.isAuthenticated
                            ? AppPalette.mint
                            : AppPalette.amber,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Session ID: ${widget.controller.sessionId}',
                        style: const TextStyle(
                          color: AppPalette.muted,
                          height: 1.5,
                        ),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
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

List<String> _splitValues(String input) {
  return input
      .split(RegExp(r'[,;\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
