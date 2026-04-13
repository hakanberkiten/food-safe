import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

class SharedScanPage extends StatefulWidget {
  const SharedScanPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SharedScanPage> createState() => _SharedScanPageState();
}

class _SharedScanPageState extends State<SharedScanPage> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  SharedScanData? _sharedScan;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _lookupSharedScan() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Once bir share token gir.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sharedScan = await widget.controller.fetchSharedScan(token);
      setState(() {
        _sharedScan = sharedScan;
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
                'Shared report lookup',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu sayfa /api/shared/{token} endpointini kullanir. Bir token gir ve paylasilan scan sonucunu geri cek.',
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
              width: 360,
              child: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share token',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        labelText: 'Token',
                        hintText: '2t_4VysaUA5h49U0AGQfsg',
                        filled: true,
                        fillColor: const Color(0xFFF3EEE5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _lookupSharedScan,
                        icon: const Icon(Icons.search_rounded),
                        label: Text(
                          _isLoading ? 'Yukleniyor...' : 'Raporu Getir',
                        ),
                      ),
                    ),
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
              child: _sharedScan == null
                  ? const EmptyState(
                      title: 'Paylasilmis rapor yuklenmedi',
                      body:
                          'History veya Analyze ekranindan aldigin share tokeni girince sonuc burada gorunecek.',
                    )
                  : AnalysisSummaryView(
                      analysis:
                          _sharedScan!.analysisResult ??
                          AnalysisOverview.fromJson(const <String, dynamic>{}),
                      footer: Text(
                        'Created at ${formatDate(_sharedScan!.createdAt)}',
                        style: const TextStyle(color: AppPalette.muted),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
