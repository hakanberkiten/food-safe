import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_models.dart';

class AppPalette {
  static const canvas = Color(0xFFF6F1E8);
  static const panel = Color(0xFFFDF9F1);
  static const ink = Color(0xFF17342D);
  static const muted = Color(0xFF61756D);
  static const forest = Color(0xFF17342D);
  static const mint = Color(0xFF2A8A75);
  static const amber = Color(0xFFB85C38);
  static const rose = Color(0xFFB5423F);
  static const sand = Color(0xFFE7D7B8);
}

BoxDecoration panelDecoration({Color color = AppPalette.panel}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(28),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A17342D),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
    ],
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.mint,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppPalette.canvas,
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(color: AppPalette.ink),
      displayMedium: GoogleFonts.dmSerifDisplay(color: AppPalette.ink),
      headlineLarge: GoogleFonts.dmSerifDisplay(color: AppPalette.ink),
      headlineMedium: GoogleFonts.dmSerifDisplay(color: AppPalette.ink),
      titleLarge: GoogleFonts.manrope(
        color: AppPalette.ink,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: GoogleFonts.manrope(color: AppPalette.ink),
      bodyMedium: GoogleFonts.manrope(color: AppPalette.ink),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide.none,
      backgroundColor: AppPalette.sand,
      labelStyle: const TextStyle(
        color: AppPalette.ink,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = AppPalette.panel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: panelDecoration(color: color),
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toUpperCase();
    Color color;
    if (normalized.contains('HIGH')) {
      color = AppPalette.rose;
    } else if (normalized.contains('CAUTION') ||
        normalized.contains('MODERATE')) {
      color = AppPalette.amber;
    } else {
      color = AppPalette.mint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.color = AppPalette.sand,
    this.textColor = AppPalette.ink,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.action,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(color: AppPalette.muted, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class AnalysisSummaryView extends StatelessWidget {
  const AnalysisSummaryView({
    super.key,
    required this.analysis,
    this.scanId,
    this.shareToken,
    this.footer,
  });

  final AnalysisOverview analysis;
  final int? scanId;
  final String? shareToken;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                analysis.productName?.trim().isNotEmpty == true
                    ? analysis.productName!
                    : 'Unnamed product scan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              StatusBadge(label: analysis.status),
              TagPill(label: '${analysis.ingredientCount} ingredients'),
              TagPill(label: analysis.detectedLanguage.toUpperCase()),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis.summary,
            style: const TextStyle(
              color: AppPalette.ink,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          _ListSection(
            title: 'Ingredients preview',
            values: analysis.ingredientsPreview,
            emptyLabel: 'No ingredients extracted.',
          ),
          const SizedBox(height: 18),
          _ListSection(
            title: 'Allergens',
            values: analysis.allergens,
            emptyLabel: 'No allergen note present.',
          ),
          const SizedBox(height: 18),
          _RiskSection(items: analysis.topRiskIngredients),
          const SizedBox(height: 18),
          _AlternativesSection(items: analysis.saferAlternatives),
          const SizedBox(height: 18),
          _ListSection(
            title: 'Scientific basis',
            values: analysis.scientificBasis,
            emptyLabel: 'No citations returned.',
          ),
          const SizedBox(height: 18),
          _ExecutionSection(traces: analysis.executionMetadata),
          if (scanId != null || shareToken != null || footer != null) ...[
            const SizedBox(height: 20),
            if (scanId != null || shareToken != null)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (scanId != null) TagPill(label: 'Scan #$scanId'),
                  if (shareToken != null) TagPill(label: 'Share: $shareToken'),
                ],
              ),
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.values,
    required this.emptyLabel,
  });

  final String title;
  final List<String> values;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text(emptyLabel, style: const TextStyle(color: AppPalette.muted))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: values.map((value) => TagPill(label: value)).toList(),
          ),
      ],
    );
  }
}

class _RiskSection extends StatelessWidget {
  const _RiskSection({required this.items});

  final List<RiskIngredient> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top risk ingredients',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text(
            'No moderate or high-risk ingredient was surfaced.',
            style: TextStyle(color: AppPalette.muted),
          )
        else
          Column(
            children: items
                .map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8EFE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Text(
                              item.ingredient,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppPalette.ink,
                              ),
                            ),
                            StatusBadge(label: item.riskLevel.toUpperCase()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.summary,
                          style: const TextStyle(
                            color: AppPalette.muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _AlternativesSection extends StatelessWidget {
  const _AlternativesSection({required this.items});

  final List<AlternativeProduct> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safer alternatives',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Text(
            'No alternative product suggestions were generated.',
            style: TextStyle(color: AppPalette.muted),
          )
        else
          Column(
            children: items
                .map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        item.reason,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                    trailing: item.tags.isEmpty
                        ? null
                        : Wrap(
                            spacing: 8,
                            children: item.tags
                                .take(2)
                                .map(
                                  (tag) => TagPill(
                                    label: tag,
                                    color: AppPalette.forest,
                                    textColor: Colors.white,
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ExecutionSection extends StatelessWidget {
  const _ExecutionSection({required this.traces});

  final List<ExecutionTrace> traces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Execution metadata',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (traces.isEmpty)
          const Text(
            'No model trace available.',
            style: TextStyle(color: AppPalette.muted),
          )
        else
          Column(
            children: traces
                .map(
                  (trace) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECE2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trace.stage.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${trace.provider} | preferred ${trace.preferredModel}',
                                style: const TextStyle(color: AppPalette.muted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Actual model: ${trace.actualModel}',
                                style: const TextStyle(color: AppPalette.muted),
                              ),
                            ],
                          ),
                        ),
                        if (trace.fallbackUsed)
                          const TagPill(
                            label: 'Fallback',
                            color: Color(0xFFF5D9CF),
                            textColor: AppPalette.rose,
                          )
                        else
                          const TagPill(
                            label: 'Primary',
                            color: Color(0xFFD8E9E1),
                            textColor: AppPalette.mint,
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

String formatDate(DateTime? value) {
  if (value == null) {
    return 'Unknown date';
  }
  final local = value.toLocal();
  final month = _monthLabel(local.month);
  return '${local.day} $month ${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _monthLabel(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
