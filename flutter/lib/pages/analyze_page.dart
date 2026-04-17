import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  late final TextEditingController _backendUrlController;

  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  bool _isLoading = false;
  bool _isSavingProduct = false;
  String? _errorMessage;
  String? _statusMessage;
  AnalyzeResponse? _response;

  @override
  void initState() {
    super.initState();
    _backendUrlController = TextEditingController(
      text: widget.controller.backendUrl,
    );
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null) {
      setState(() {
        _errorMessage = 'Dosya byte verisi okunamadi.';
      });
      return;
    }

    setState(() {
      _selectedFile = file;
      _selectedFileBytes = file.bytes;
      _errorMessage = null;
      _statusMessage = null;
    });
  }

  Future<void> _analyze() async {
    if (_selectedFile == null || _selectedFileBytes == null) {
      setState(() {
        _errorMessage = 'Please select a label image first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      await widget.controller.setBackendUrl(_backendUrlController.text);
      final result = await widget.controller.analyze(
        bytes: _selectedFileBytes!,
        filename: _selectedFile!.name,
      );
      setState(() {
        _response = result;
        _statusMessage = 'Analiz tamamlandi.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkBackend() async {
    setState(() {
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      await widget.controller.setBackendUrl(_backendUrlController.text);
      await widget.controller.refreshHealth();
      setState(() {
        _statusMessage = widget.controller.healthMessage;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _saveProduct() async {
    final response = _response;
    if (response == null) {
      return;
    }

    setState(() {
      _isSavingProduct = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final message = await widget.controller.saveProduct(response.scanId);
      setState(() {
        _statusMessage = message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isSavingProduct = false;
      });
    }
  }

  Future<void> _copyShareToken() async {
    final token = _response?.shareToken;
    if (token == null || token.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share token copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackendCard(),
          const SizedBox(height: 32),
          _buildStepHeader(
            step: '1',
            title: 'Upload Label',
            subtitle: 'Snap a clear photo of product ingredients.',
          ),
          const SizedBox(height: 16),
          _buildImagePicker(),
          const SizedBox(height: 32),
          _buildStepHeader(
            step: '2',
            title: 'AI Analysis',
            subtitle: 'We cross-reference ingredients with your profile.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _analyze,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: AppPalette.amber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.psychology_rounded),
              label: Text(
                _isLoading ? 'Analyzing...' : 'Start Health Scan',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (_statusMessage != null || _errorMessage != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _statusMessage ?? _errorMessage!,
                style: TextStyle(
                  color: _errorMessage != null
                      ? AppPalette.rose
                      : AppPalette.mint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          if (_response != null) ...[
            _buildStepHeader(
              step: '3',
              title: 'Safety Report',
              subtitle: 'Detailed breakdown and risk level.',
            ),
            const SizedBox(height: 16),
            AnalysisSummaryView(
              analysis: _response!.result,
              scanId: _response!.scanId,
              shareToken: _response!.shareToken,
              footer: _buildAnalysisFooter(),
            ),
          ] else
            const EmptyState(
              title: 'No scan result yet',
              body:
                  'Complete steps 1 and 2 to generate your personalized health safety report.',
            ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildBackendCard() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final reachable = widget.controller.backendReachable;
        final statusText =
            widget.controller.healthMessage ??
            'Set your backend URL and test the connection.';

        return AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    reachable
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    color: reachable ? AppPalette.emerald : AppPalette.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reachable
                          ? 'Backend Connected'
                          : 'Backend Connection Needed',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                statusText,
                style: const TextStyle(color: AppPalette.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _backendUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Backend URL',
                  hintText: 'http://127.0.0.1:8000',
                  filled: true,
                  fillColor: const Color(0xFFF3EEE5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _checkBackend,
                    icon: const Icon(Icons.wifi_find_rounded),
                    label: const Text('Test Connection'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _backendUrlController.text = widget.controller.backendUrl;
                      _checkBackend();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Use Current URL'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Android emulator: http://10.0.2.2:8000 | iOS simulator/macOS: http://127.0.0.1:8000 | Physical phone: http://YOUR_LOCAL_IP:8000',
                style: TextStyle(
                  color: AppPalette.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepHeader({
    required String step,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppPalette.mint,
                shape: BoxShape.circle,
              ),
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppPalette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            subtitle,
            style: const TextStyle(color: AppPalette.muted, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return AppPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppPalette.mint.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: _selectedFileBytes == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      size: 48,
                      color: AppPalette.mint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Select Product Label',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.mint,
                      ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        _selectedFileBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnalysisFooter() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: _copyShareToken,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Share Token'),
        ),
        if (widget.controller.isAuthenticated)
          FilledButton.icon(
            onPressed: _isSavingProduct ? null : _saveProduct,
            icon: const Icon(Icons.bookmark_add_rounded),
            label: Text(_isSavingProduct ? 'Saving...' : 'Save to List'),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppPalette.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Sign in to save products',
              style: TextStyle(
                color: AppPalette.amber,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
