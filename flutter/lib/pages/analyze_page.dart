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
        _errorMessage = 'Once bir etiket gorseli sec.';
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
      const SnackBar(content: Text('Share token panoya kopyalandi.')),
    );
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
                'Etiketi yukle, V2Q akisini calistir.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu sayfa /api/analyze/ endpointine multipart upload yapar, session veya auth baglamini ekler ve kompakt risk raporunu getirir.',
                style: TextStyle(color: Color(0xFFD7E7DF), height: 1.6),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _backendUrlController,
                decoration: InputDecoration(
                  labelText: 'Backend URL',
                  hintText: 'http://127.0.0.1:8000',
                  filled: true,
                  fillColor: const Color(0xFFF8F2E8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
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
              width: 360,
              child: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input asset',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFFF0E9DC),
                      ),
                      child: _selectedFileBytes == null
                          ? const Center(
                              child: Text(
                                'PNG, JPG veya WEBP sec',
                                style: TextStyle(color: AppPalette.muted),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.memory(
                                _selectedFileBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFile != null)
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Etiket Sec'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _analyze,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.amber,
                        ),
                        child: Text(
                          _isLoading ? 'Analiz ediliyor...' : 'Analiz Et',
                        ),
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
              width: 720,
              child: _response == null
                  ? const EmptyState(
                      title: 'Sonuc burada gorunecek',
                      body:
                          'Etiketi gonderdiginde scan id, share token ve risk raporu bu panelde acilacak.',
                    )
                  : AnalysisSummaryView(
                      analysis: _response!.result,
                      scanId: _response!.scanId,
                      shareToken: _response!.shareToken,
                      footer: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copyShareToken,
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Token Kopyala'),
                          ),
                          if (widget.controller.isAuthenticated)
                            FilledButton.icon(
                              onPressed: _isSavingProduct ? null : _saveProduct,
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: Text(
                                _isSavingProduct
                                    ? 'Kaydediliyor...'
                                    : 'Kaydedilenlere Ekle',
                              ),
                            )
                          else
                            const Text(
                              'Kaydetme icin giris yapman gerekiyor.',
                              style: TextStyle(color: AppPalette.muted),
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
