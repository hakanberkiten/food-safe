import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../widgets/ui.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final lastAnalysis = controller.lastAnalysis;
    return ListView(
      children: [
        AppPanel(
          color: AppPalette.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Control Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tum endpointleri tek panelden yonet, taramayi hizlica yap, sonucu paylas.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFFF8F2E8),
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bu dashboard root health check, auth state, anonim session, son analiz ve temel aksiyonlari tek yerde toplar.',
                style: TextStyle(
                  color: Color(0xFFD7E7DF),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => onNavigate(1),
                    icon: const Icon(Icons.document_scanner_rounded),
                    label: const Text('Yeni Tarama'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        onNavigate(controller.isAuthenticated ? 3 : 6),
                    icon: Icon(
                      controller.isAuthenticated
                          ? Icons.history_rounded
                          : Icons.login_rounded,
                    ),
                    label: Text(
                      controller.isAuthenticated ? 'Gecmise Git' : 'Giris Yap',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.refreshHealth,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Health Check'),
                  ),
                ],
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
              width: 330,
              child: _MetricCard(
                title: 'Backend',
                value: controller.backendReachable ? 'Online' : 'Offline',
                body: controller.healthMessage ?? 'Health state unknown.',
              ),
            ),
            SizedBox(
              width: 330,
              child: _MetricCard(
                title: 'Auth State',
                value: controller.isAuthenticated ? 'Signed In' : 'Anonymous',
                body: controller.isAuthenticated
                    ? controller.currentEmail ?? 'Authenticated session'
                    : 'Profile and analyze can run with session_id fallback.',
              ),
            ),
            SizedBox(
              width: 330,
              child: _MetricCard(
                title: 'Session',
                value: controller.sessionId.substring(0, 12),
                body: 'Anonymous scans and profile drafts are attached here.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: 480,
              child: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Endpoint map',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const _EndpointTile(
                      method: 'GET',
                      path: '/',
                      note: 'API root ping',
                    ),
                    const _EndpointTile(
                      method: 'POST',
                      path: '/api/auth/signup',
                      note: 'Create account',
                    ),
                    const _EndpointTile(
                      method: 'POST',
                      path: '/api/auth/login',
                      note: 'Token login',
                    ),
                    const _EndpointTile(
                      method: 'GET/POST',
                      path: '/api/profile/',
                      note: 'Profile read and update',
                    ),
                    const _EndpointTile(
                      method: 'POST',
                      path: '/api/analyze/',
                      note: 'Image upload and safety reasoning',
                    ),
                    const _EndpointTile(
                      method: 'GET',
                      path: '/api/history/scans',
                      note: 'User scan history',
                    ),
                    const _EndpointTile(
                      method: 'GET',
                      path: '/api/history/saved-products',
                      note: 'Saved product shortlist',
                    ),
                    const _EndpointTile(
                      method: 'POST',
                      path: '/api/history/save-product',
                      note: 'Promote a scan into saved list',
                    ),
                    const _EndpointTile(
                      method: 'GET',
                      path: '/api/shared/{token}',
                      note: 'Public report lookup',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 520,
              child: lastAnalysis == null
                  ? EmptyState(
                      title: 'Henüz tarama yok',
                      body:
                          'Analyze sayfasından bir etiket yuklediğinde son rapor burada kisa ozet halinde gorunecek.',
                      action: FilledButton(
                        onPressed: () => onNavigate(1),
                        child: const Text('Analyze Sayfasina Git'),
                      ),
                    )
                  : AnalysisSummaryView(
                      analysis: lastAnalysis.result,
                      scanId: lastAnalysis.scanId,
                      shareToken: lastAnalysis.shareToken,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.body,
  });

  final String title;
  final String value;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({
    required this.method,
    required this.path,
    required this.note,
  });

  final String method;
  final String path;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TagPill(
            label: method,
            color: const Color(0xFFD8E9E1),
            textColor: AppPalette.mint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(note, style: const TextStyle(color: AppPalette.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
