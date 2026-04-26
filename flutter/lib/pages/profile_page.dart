import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

import '../pages/auth_page.dart';

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

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _allergiesController = TextEditingController();
    _conditionsController = TextEditingController();
    _specialController = TextEditingController();
    widget.controller.addListener(_handleControllerChange);
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
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
    if (mounted) {
      setState(() {});
      if (widget.controller.isAuthenticated) {
        _loadProfile();
      }
    }
  }

  Future<void> _loadProfile() async {
    if (!widget.controller.isAuthenticated && widget.controller.sessionId.isEmpty) return;

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
      if (mounted) setState(() => _isLoading = false);
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
        sessionId: widget.controller.isAuthenticated ? null : widget.controller.sessionId,
      );
      await widget.controller.saveProfile(payload);
      setState(() => _statusMessage = 'Profile updated successfully.');
    } catch (error) {
      setState(() => _errorMessage = error.toString());
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isAuthenticated) {
      return AuthPage(controller: widget.controller);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoHeader(context),
          const SizedBox(height: 32),
          Text(
            'Health Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else
            AppPanel(
              child: Column(
                children: [
                  _ProfileField(
                    controller: _allergiesController,
                    label: 'Allergies',
                    hint: 'e.g. gluten, soy, peanut, lactose',
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _conditionsController,
                    label: 'Chronic Diseases',
                    hint: 'e.g. celiac, hypertension, diabetes',
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _specialController,
                    label: 'Special Dietary Needs',
                    hint: 'e.g. vegan, pregnant, low sodium',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          _buildUsageInfo(context),
          const SizedBox(height: 40),
          Center(
            child: TextButton.icon(
              onPressed: () => widget.controller.logout(),
              style: TextButton.styleFrom(foregroundColor: AppPalette.rose),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout and Sign Out'),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader(BuildContext context) {
    return AppPanel(
      color: AppPalette.forest,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.controller.currentEmail ?? 'Active User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Cloud-synced profile active',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInfo(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How this is used',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your profile data is used during the reasoning stage to match ingredients with health triggers. This allows the AI to provide personalized safety scores.',
            style: TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ],
      ),
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
