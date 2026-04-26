import 'package:flutter/material.dart';
import '../app/app_controller.dart';
import '../widgets/ui.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickActions(controller: controller, onNavigate: onNavigate),
                  const SizedBox(height: 32),
                  _StatisticsRow(controller: controller),
                  const SizedBox(height: 32),
                  _RecentActivityPlaceholder(controller: controller, onNavigate: onNavigate),
                ],
              ),
            ),
            const SizedBox(height: 100), // Bottom nav spacer
          ],
        ),
      ),
    );
  }
}


class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller, required this.onNavigate});
  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.camera_alt_rounded,
                label: 'Scan Label',
                subtitle: 'Vision AI Analysis',
                color: AppPalette.emerald,
                onTap: () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                icon: Icons.history_rounded,
                label: 'History',
                subtitle: 'Your Past Scans',
                color: AppPalette.ink,
                onTap: () => onNavigate(controller.isAuthenticated ? 2 : 3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPalette.panel,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppPalette.ink.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppPalette.ink,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppPalette.muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: 'Safe Products',
            count: controller.safeProducts.toString(),
            icon: Icons.verified_user_rounded,
            color: AppPalette.emerald,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatItem(
            label: 'Total Scans',
            count: controller.totalScans.toString(),
            icon: Icons.qr_code_scanner_rounded,
            color: AppPalette.amber,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final String count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.sand.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppPalette.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecentActivityPlaceholder extends StatelessWidget {
  const _RecentActivityPlaceholder({required this.controller, required this.onNavigate});
  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final lastAnalysis = controller.lastAnalysis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppPalette.mint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppPalette.mint),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Analyze',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Upload a product label to get started.',
                          style: TextStyle(color: AppPalette.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => onNavigate(1),
                    icon: const Icon(Icons.document_scanner_rounded),
                    label: const Text('New Scan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(controller.isAuthenticated ? 2 : 3),
                    icon: Icon(
                      controller.isAuthenticated ? Icons.history_rounded : Icons.login_rounded,
                    ),
                    label: Text(
                      controller.isAuthenticated ? 'View History' : 'Login Now',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (lastAnalysis != null) ...[
          const SizedBox(height: 24),
          Text(
            'Latest Result',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          AnalysisSummaryView(
            analysis: lastAnalysis.result,
            scanId: lastAnalysis.scanId,
            shareToken: lastAnalysis.shareToken,
          ),
        ] else ...[
          const SizedBox(height: 24),
          EmptyState(
            title: 'No recent scans',
            body: 'Your latest analysis results will appear here for quick access.',
            action: OutlinedButton(
              onPressed: () => onNavigate(1),
              child: const Text('Start First Scan'),
            ),
          ),
        ],
      ],
    );
  }
}
