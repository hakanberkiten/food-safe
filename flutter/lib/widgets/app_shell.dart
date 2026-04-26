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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(controller: widget.controller, onNavigate: (i) => setState(() => _selectedIndex = i)),
      AnalyzePage(controller: widget.controller),
      HistoryPage(controller: widget.controller, onNavigate: (i) => setState(() => _selectedIndex = i)),
      ProfilePage(controller: widget.controller),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFFFBF9F4),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedIndex == 0)
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: AppPalette.ink.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  _selectedIndex == 0 
                      ? (widget.controller.isAuthenticated 
                          ? (widget.controller.currentEmail?.split('@').first ?? 'User')
                          : 'Guest User')
                      : _getTabTitle(_selectedIndex),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppPalette.ink),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 3),
                  icon: const Icon(Icons.person_rounded, size: 24),
                  label: Text(
                    widget.controller.isAuthenticated 
                        ? (widget.controller.currentEmail?.split('@').first ?? 'User')
                        : 'Guest',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppPalette.mint.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            decoration: BoxDecoration(
              color: AppPalette.forest,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.forest.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                selectedItemColor: AppPalette.gold,
                unselectedItemColor: Colors.white.withValues(alpha: 0.5),
                elevation: 0,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_rounded),
                    activeIcon: Icon(Icons.explore_rounded, color: AppPalette.gold),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code_scanner_rounded),
                    activeIcon: Icon(Icons.qr_code_scanner_rounded, color: AppPalette.gold),
                    label: 'Scan',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_rounded),
                    activeIcon: Icon(Icons.history_rounded, color: AppPalette.gold),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    activeIcon: Icon(Icons.person_rounded, color: AppPalette.gold),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 1: return 'Health Scan';
      case 2: return 'Scan History';
      case 3: return 'Account & Health';
      default: return '';
    }
  }
}
