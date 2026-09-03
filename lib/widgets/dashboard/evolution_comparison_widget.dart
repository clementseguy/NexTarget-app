import 'package:flutter/material.dart';

import '../../models/dashboard_data.dart';

/// Comparatif global 30 j / 90 j de NT-014, présenté sur deux lignes.
class EvolutionComparisonWidget extends StatelessWidget {
  final EvolutionComparisonData? data;
  final bool isLoading;

  const EvolutionComparisonWidget({
    super.key,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final evolutionData = data ??
        const EvolutionComparisonData.empty(
          'Dynamique des performances · 30 j vs 90 j',
        );
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const SizedBox(
                height: 144,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    evolutionData.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (!evolutionData.hasRequiredPopulation)
                    const _InsufficientOverallState()
                  else ...[
                    _MetricLine(
                      title: 'Points par série',
                      unit: 'pts',
                      data: evolutionData.score,
                      icon: Icons.trending_up,
                    ),
                    const Divider(height: 24),
                    _MetricLine(
                      title: 'Groupement par série',
                      unit: 'cm',
                      data: evolutionData.groupSize,
                      lowerIsBetter: true,
                      icon: Icons.center_focus_strong,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _InsufficientOverallState extends StatelessWidget {
  const _InsufficientOverallState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Comparatif indisponible, données insuffisantes',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Données insuffisantes : il faut au moins une série sur les '
            '30 derniers jours et une autre entre J-90 et J-31.',
          ),
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String title;
  final String unit;
  final EvolutionMetricComparison data;
  final bool lowerIsBetter;
  final IconData icon;

  const _MetricLine({
    required this.title,
    required this.unit,
    required this.data,
    required this.icon,
    this.lowerIsBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    final precision = _comparisonPrecision();
    return Semantics(
      container: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!data.hasComparison)
            Text(
              'Données insuffisantes pour cette métrique : une série '
              'exploitable est requise dans chaque période.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ValueBlock(
                  label: '30 j',
                  value: '${_decimal(data.avg30Days!, precision)} $unit',
                ),
                _ValueBlock(
                  label: '90 j',
                  value: '${_decimal(data.avg90Days!, precision)} $unit',
                ),
                _ValueBlock(
                  label: 'Delta',
                  value: _deltaLabel(),
                  compact: true,
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (data.hasSparkline)
            _Sparkline(
              points: data.sessionPoints,
              title: title,
              unit: unit,
            )
          else
            Text(
              'Tendance masquée : ${data.sessionPoints.length}/5 sessions '
              'exploitables.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  String _deltaLabel() {
    final precision = _comparisonPrecision();
    final absolute = _signedDecimal(data.absoluteDelta!, unit, precision);
    final relative = data.relativeDeltaPercent;
    if (relative == null) {
      return '$absolute · pourcentage indisponible (base 90 j nulle)';
    }
    if (lowerIsBetter) {
      return '$absolute · ${_signedDecimal(-relative, '%', 1)}';
    }
    return '$absolute · ${_signedDecimal(relative, '%', 1)}';
  }

  int _comparisonPrecision() {
    if (!data.hasComparison || data.absoluteDelta == 0) return 1;
    final rounded30 = data.avg30Days!.toStringAsFixed(1);
    final rounded90 = data.avg90Days!.toStringAsFixed(1);
    return rounded30 == rounded90 ? 2 : 1;
  }
}

class _ValueBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _ValueBlock({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          value,
          style: (compact
                  ? Theme.of(context).textTheme.bodyMedium
                  : Theme.of(context).textTheme.bodyLarge)
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<SessionMetricPoint> points;
  final String title;
  final String unit;

  const _Sparkline({
    required this.points,
    required this.title,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final first = points.first.value;
    final last = points.last.value;
    final semanticsLabel = '$title, tendance sur ${points.length} sessions, '
        'de ${_decimal(first, 1)} à ${_decimal(last, 1)} $unit, ancien vers récent';
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: CustomPaint(
              key: ValueKey('sparkline-$title'),
              painter: _SparklinePainter(
                values: points.map((point) => point.value).toList(),
                lineColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                'Ancien ${_decimal(first, 1)} $unit',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'Récent ${_decimal(last, 1)} $unit',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          Text(
            '${points.length} sessions · un point par session',
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  const _SparklinePainter({
    required this.values,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 3.0;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    Offset offsetFor(int index) {
      final x = values.length == 1
          ? size.width / 2
          : index * size.width / (values.length - 1);
      final normalized = range == 0 ? 0.5 : (values[index] - minValue) / range;
      final y = size.height - inset - normalized * (size.height - inset * 2);
      return Offset(x, y);
    }

    final path = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (var index = 1; index < values.length; index++) {
      final point = offsetFor(index);
      path.lineTo(point.dx, point.dy);
    }
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    for (var index = 0; index < values.length; index++) {
      canvas.drawCircle(offsetFor(index), 2.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}

String _decimal(double value, int precision) =>
    value.toStringAsFixed(precision).replaceAll('.', ',');

String _signedDecimal(double value, String unit, int precision) {
  if (value == 0) return '±${_decimal(0, precision)} $unit';
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_decimal(value, precision)} $unit';
}
