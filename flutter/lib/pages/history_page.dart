import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late bool _lastAuthState;
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
  List<ScanHistoryItem> _scans = const [];
  ScanHistoryItem? _selectedScan;

  @override
  void initState() {
    super.initState();
    _lastAuthState = widget.controller.isAuthenticated;
    widget.controller.addListener(_handleControllerChange);
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
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
    super.dispose();
  }

  void _handleControllerChange() {
    final authState = widget.controller.isAuthenticated;
    if (_lastAuthState == authState) {
      return;
    }
    _lastAuthState = authState;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!widget.controller.isAuthenticated) {
      setState(() {
        _scans = const [];
        _selectedScan = null;
        _errorMessage = null;
        _statusMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final scans = await widget.controller.fetchScans();
      setState(() {
        _scans = scans;
        _selectedScan = scans.isEmpty ? null : scans.first;
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

  Future<void> _saveSelectedScan() async {
    final selected = _selectedScan;
    if (selected == null) {
      return;
    }

    setState(() {
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final message = await widget.controller.saveProduct(selected.id);
      setState(() {
        _statusMessage = message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _copyShareToken() async {
    final token = _selectedScan?.shareToken;
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
    if (!widget.controller.isAuthenticated) {
      return const EmptyState(
        title: 'History kilitli',
        body:
            'Bu sayfa /api/history/scans endpointini kullanir ve token gerektirir. Auth sayfasindan giris yapinca kullanima acilacak.',
      );
    }

    return ListView(
      children: [
        AppPanel(
          color: AppPalette.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan history',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '/api/history/scans endpointinden kullaniciya ait taramalar cekiliyor. Buradan kaydetme ve paylasim token kopyalama da yapilabiliyor.',
                style: TextStyle(color: Color(0xFFD7E7DF), height: 1.6),
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
                width: 380,
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Scans',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadHistory,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_scans.isEmpty)
                        const Text(
                          'Henüz scan history kaydı yok.',
                          style: TextStyle(color: AppPalette.muted),
                        )
                      else
                        ..._scans.map(
                          (scan) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: scan.id == _selectedScan?.id
                                  ? const Color(0xFFE7F1EC)
                                  : const Color(0xFFF2ECE2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedScan = scan;
                                });
                              },
                              title: Text(
                                scan.productName?.trim().isNotEmpty == true
                                    ? scan.productName!
                                    : 'Scan #${scan.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                formatDate(scan.createdAt),
                                style: const TextStyle(color: AppPalette.muted),
                              ),
                              trailing: StatusBadge(label: scan.dangerLevel),
                            ),
                          ),
                        ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: AppPalette.mint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
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
                width: 700,
                child: _selectedScan == null
                    ? const EmptyState(
                        title: 'Detay secilmedi',
                        body: 'Sol taraftan bir scan secerek detay kartini ac.',
                      )
                    : AnalysisSummaryView(
                        analysis:
                            _selectedScan!.analysisResult ??
                            AnalysisOverview.fromJson(
                              const <String, dynamic>{},
                            ),
                        scanId: _selectedScan!.id,
                        shareToken: _selectedScan!.shareToken,
                        footer: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _saveSelectedScan,
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: const Text('Saved Listesine Ekle'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _copyShareToken,
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Token Kopyala'),
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
