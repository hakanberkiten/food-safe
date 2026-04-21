import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<int> onNavigate;

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
      const SnackBar(content: Text('Share token copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isAuthenticated) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          title: 'History Locked',
          body: 'Personalized scan history requires an account. Sign in to access your past analyses.',
          action: FilledButton.icon(
            onPressed: () => widget.onNavigate(3),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign In Now'),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: AppPanel(
                color: AppPalette.rose.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppPalette.rose, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppPalette.rose, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          else if (_scans.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: EmptyState(
                title: 'No History',
                body: 'Your analyzed products will appear here. Start by scanning a product label!',
              ),
            )
          else
            ..._scans.map((scan) => _HistoryCard(
              scan: scan,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _HistoryDetailView(
                    scan: scan,
                    controller: widget.controller,
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.scan, required this.onTap});

  final ScanHistoryItem scan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppPalette.mint.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.description_outlined, color: AppPalette.mint),
        ),
        title: Text(
          scan.productName?.trim().isNotEmpty == true ? scan.productName! : 'Product Scan #${scan.id}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        subtitle: Text(
          formatDate(scan.createdAt),
          style: const TextStyle(color: AppPalette.muted, fontSize: 12),
        ),
        trailing: StatusBadge(label: scan.dangerLevel),
      ),
    );
  }
}

class _HistoryDetailView extends StatelessWidget {
  const _HistoryDetailView({required this.scan, required this.controller});

  final ScanHistoryItem scan;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F4),
      appBar: AppBar(
        title: const Text('Scan Result', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnalysisSummaryView(
          analysis: scan.analysisResult ?? AnalysisOverview.fromJson(const {}),
          scanId: scan.id,
          shareToken: scan.shareToken,
          footer: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await controller.saveProduct(scan.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to your list.')));
                  }
                },
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Add to Saved'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: scan.shareToken ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token copied.')));
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Copy Token'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
