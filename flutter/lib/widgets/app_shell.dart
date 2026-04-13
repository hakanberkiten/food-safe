import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../pages/analyze_page.dart';
import '../pages/auth_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/history_page.dart';
import '../pages/profile_page.dart';
import '../pages/saved_products_page.dart';
import '../pages/shared_scan_page.dart';
import 'ui.dart';

class FoodSafeShell extends StatefulWidget {
  const FoodSafeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<FoodSafeShell> createState() => _FoodSafeShellState();
}

class _FoodSafeShellState extends State<FoodSafeShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<_ShellDestination> get _destinations => [
    _ShellDestination(
      label: 'Overview',
      icon: Icons.space_dashboard_rounded,
      builder: () => DashboardPage(
        controller: widget.controller,
        onNavigate: _selectIndex,
      ),
    ),
    _ShellDestination(
      label: 'Analyze',
      icon: Icons.document_scanner_rounded,
      builder: () => AnalyzePage(controller: widget.controller),
    ),
    _ShellDestination(
      label: 'Profile',
      icon: Icons.health_and_safety_rounded,
      builder: () => ProfilePage(controller: widget.controller),
    ),
    _ShellDestination(
      label: 'History',
      icon: Icons.history_rounded,
      builder: () => HistoryPage(controller: widget.controller),
    ),
    _ShellDestination(
      label: 'Saved',
      icon: Icons.bookmark_rounded,
      builder: () => SavedProductsPage(controller: widget.controller),
    ),
    _ShellDestination(
      label: 'Shared',
      icon: Icons.share_rounded,
      builder: () => SharedScanPage(controller: widget.controller),
    ),
    _ShellDestination(
      label: 'Auth',
      icon: Icons.manage_accounts_rounded,
      builder: () => AuthPage(controller: widget.controller),
    ),
  ];

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            return Scaffold(
              key: _scaffoldKey,
              appBar: isWide
                  ? null
                  : AppBar(
                      title: const Text('Gemma 4 Food-Safe'),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: AppPalette.ink,
                    ),
              drawer: isWide
                  ? null
                  : Drawer(
                      child: _Sidebar(
                        controller: widget.controller,
                        destinations: _destinations,
                        selectedIndex: _selectedIndex,
                        onSelect: _selectIndex,
                      ),
                    ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF3E6CF), Color(0xFFF6F1E8)],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: 260,
                            child: _Sidebar(
                              controller: widget.controller,
                              destinations: _destinations,
                              selectedIndex: _selectedIndex,
                              onSelect: _selectIndex,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isWide ? 0 : 16,
                            24,
                            24,
                            24,
                          ),
                          child: Column(
                            children: [
                              _TopStatusBar(controller: widget.controller),
                              const SizedBox(height: 18),
                              Expanded(
                                child: IndexedStack(
                                  index: _selectedIndex,
                                  children: _destinations
                                      .map((item) => item.builder())
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.controller,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
  });

  final AppController controller;
  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      color: AppPalette.forest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppPalette.mint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Gemma 4 Food-Safe',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vision-to-Query cockpit for the full backend surface.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFD5E7DF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final item = destinations[index];
                final selected = index == selectedIndex;
                return InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2A8A75)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemCount: destinations.length,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            controller.isAuthenticated
                ? 'Signed in as ${controller.currentEmail}'
                : 'Anonymous session active',
            style: const TextStyle(color: Color(0xFFD5E7DF)),
          ),
        ],
      ),
    );
  }
}

class _TopStatusBar extends StatelessWidget {
  const _TopStatusBar({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TagPill(label: controller.backendUrl),
          StatusBadge(
            label: controller.backendReachable ? 'BACKEND_OK' : 'BACKEND_DOWN',
          ),
          TagPill(
            label: controller.isAuthenticated ? 'AUTH_READY' : 'ANON_MODE',
            color: controller.isAuthenticated
                ? const Color(0xFFD8E9E1)
                : const Color(0xFFF5E4D9),
            textColor: controller.isAuthenticated
                ? AppPalette.mint
                : AppPalette.amber,
          ),
          TagPill(label: 'Session ${controller.sessionId.substring(0, 8)}'),
          if (controller.healthMessage != null)
            Text(
              controller.healthMessage!,
              style: const TextStyle(
                color: AppPalette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final Widget Function() builder;
}
