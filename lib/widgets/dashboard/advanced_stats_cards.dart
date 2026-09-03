import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/mobile_utils.dart';
import 'stat_card.dart';

/// Widget affichant les 4 cartes statistiques avancées
/// - Sessions ce mois
/// - Catégorie dominante
/// - Régularité
/// - Progression du score et du groupement selon le comparatif 30 j / 90 j
class AdvancedStatsCards extends StatelessWidget {
  final AdvancedStatsData? data;
  final EvolutionComparisonData? comparisonData;
  final DashboardSummary summary;
  final bool isLoading;

  const AdvancedStatsCards({
    super.key,
    this.data,
    this.comparisonData,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final statsData = data ?? const AdvancedStatsData.empty();

    // Utilisation de la même architecture que StatsSummaryCards
    final spacing = MobileUtils.getSpacing(context);
    final isMobile = MobileUtils.isMobile(context);
    final isVeryNarrow = MediaQuery.sizeOf(context).width <= 340;

    return GridView.count(
      crossAxisCount: 2, // 2 colonnes pour 4 cartes
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? (isVeryNarrow ? 1.8 : 2.2) : 1.6,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      children: [
        StatCard(
          title: 'Sessions ce mois',
          value: '${summary.sessionsThisMonth}',
          unit: '',
          icon: Icons.calendar_today,
          color: Colors.purple,
        ),
        StatCard(
          title: 'Prise dominante',
          value: _formatDominantHandMethod(statsData.dominantHandMethod,
              statsData.dominantHandMethodPercentage),
          unit: '',
          icon: Icons.back_hand,
          color: Theme.of(context).colorScheme.primary,
        ),
        StatCard(
          title: 'Régularité',
          value: _formatConsistency(statsData.consistency),
          unit: '',
          icon: Icons.track_changes,
          color: _getConsistencyColor(statsData.consistency),
        ),
        _ComparisonProgressCard(
          data: comparisonData,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = MobileUtils.getSpacing(context);
        final isMobile = MobileUtils.isMobile(context);
        final isVeryNarrow = MediaQuery.sizeOf(context).width <= 340;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? (isVeryNarrow ? 1.8 : 2.2) : 1.6,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          children: List.generate(4, (index) => const StatCardLoading()),
        );
      },
    );
  }

  String _formatConsistency(double consistency) {
    if (consistency < 0) return '-';
    return '${consistency.toStringAsFixed(1)}%';
  }

  String _formatDominantHandMethod(String? handMethod, double percentage) {
    if (handMethod == null) return '-';
    final methodLabel = handMethod == 'one' ? '1 main' : '2 mains';
    return '$methodLabel (${percentage.toStringAsFixed(1)}%)';
  }

  Color _getConsistencyColor(double consistency) {
    if (consistency < 0) return Colors.grey;
    if (consistency >= 80) return Colors.green;
    if (consistency >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _ComparisonProgressCard extends StatelessWidget {
  final EvolutionComparisonData? data;
  final Color color;

  const _ComparisonProgressCard({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final comparison = data ??
        const EvolutionComparisonData.empty(
          'Dynamique des performances · 30 j vs 90 j',
        );
    final isMobile = MobileUtils.isMobile(context);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 16 : null,
          color: color,
        );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: color,
                  size: isMobile ? 18 : 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Progression',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 11 : null,
                        ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _ProgressValue(
                    icon: Icons.center_focus_strong,
                    semanticsLabel: 'Groupement',
                    value: _formatPercent(
                      comparison.groupSize.relativeDeltaPercent == null
                          ? null
                          : -comparison.groupSize.relativeDeltaPercent!,
                    ),
                    style: textStyle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ProgressValue(
                    icon: Icons.trending_up,
                    semanticsLabel: 'Score',
                    value: _formatPercent(
                      comparison.score.relativeDeltaPercent,
                    ),
                    style: textStyle,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPercent(double? value) {
    if (value == null) return '-';
    final normalized = value == 0 ? 0.0 : value;
    final sign = normalized > 0
        ? '+'
        : normalized == 0
            ? '±'
            : '';
    return '$sign${normalized.toStringAsFixed(1).replaceAll('.', ',')} %';
  }
}

class _ProgressValue extends StatelessWidget {
  final IconData icon;
  final String semanticsLabel;
  final String value;
  final TextStyle? style;
  final bool alignEnd;

  const _ProgressValue({
    required this.icon,
    required this.semanticsLabel,
    required this.value,
    required this.style,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticsLabel : $value',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, semanticLabel: semanticsLabel),
            const SizedBox(width: 4),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }
}
