import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/app_models.dart';
import '../widgets/ui.dart';

class SavedProductsPage extends StatefulWidget {
  const SavedProductsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SavedProductsPage> createState() => _SavedProductsPageState();
}

class _SavedProductsPageState extends State<SavedProductsPage> {
  late bool _lastAuthState;
  bool _isLoading = false;
  String? _errorMessage;
  List<SavedProductItem> _items = const [];
  SavedProductItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _lastAuthState = widget.controller.isAuthenticated;
    widget.controller.addListener(_handleControllerChange);
    _loadSavedProducts();
  }

  @override
  void didUpdateWidget(covariant SavedProductsPage oldWidget) {
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
    _loadSavedProducts();
  }

  Future<void> _loadSavedProducts() async {
    if (!widget.controller.isAuthenticated) {
      setState(() {
        _items = const [];
        _selectedItem = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.controller.fetchSavedProducts();
      setState(() {
        _items = items;
        _selectedItem = items.isEmpty ? null : items.first;
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
    if (!widget.controller.isAuthenticated) {
      return const EmptyState(
        title: 'Saved list kilitli',
        body:
            'Bu sayfa /api/history/saved-products endpointine bagli. Kaydedilen urunleri gormek icin once giris yap.',
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
                'Saved products',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu sayfa /api/history/saved-products endpointini gosterir. Once history veya analyze ekranindan scan kaydetmen gerekir.',
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
                width: 360,
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Saved list',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadSavedProducts,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const Text(
                          'Kaydedilen urun bulunmuyor.',
                          style: TextStyle(color: AppPalette.muted),
                        )
                      else
                        ..._items.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: item.id == _selectedItem?.id
                                  ? const Color(0xFFE7F1EC)
                                  : const Color(0xFFF2ECE2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedItem = item;
                                });
                              },
                              title: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                formatDate(item.createdAt),
                                style: const TextStyle(color: AppPalette.muted),
                              ),
                              trailing: StatusBadge(label: item.dangerLevel),
                            ),
                          ),
                        ),
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
                width: 720,
                child: _selectedItem == null
                    ? const EmptyState(
                        title: 'Saved detay secilmedi',
                        body: 'Sol taraftaki kayittan bir urun sec.',
                      )
                    : AnalysisSummaryView(
                        analysis:
                            _selectedItem!.analysisResult ??
                            AnalysisOverview.fromJson(
                              const <String, dynamic>{},
                            ),
                      ),
              ),
            ],
          ),
      ],
    );
  }
}
