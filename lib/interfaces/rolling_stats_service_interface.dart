import '../services/stats_contract.dart';

/// Interface pour le service de calcul des statistiques roulantes
abstract class IRollingStatsService extends RollingStatsCalculator {
  /// Calcule le total moyen par session sur 30 j et 60 j.
  ///
  /// Cette statistique legacy, non affichée dans le dashboard, est distincte du
  /// comparatif par série 30 j / 90 j de NT-014.
  @override
  Future<RollingStatsSnapshot> compute();
}
