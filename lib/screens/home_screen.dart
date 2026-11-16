import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/rules_bottom_sheet.dart';
import '../widgets/dashboard/dashboard_tab_view.dart';
import '../widgets/app_bar_title.dart';
import '../services/session_service.dart';
import '../models/shooting_session.dart';
import '../widgets/help_button.dart';
import '../services/server_wake_service.dart';

const dashboardStatisticsHelpPoints = <String>[
  'Régularité : indice de stabilité des scores sur les 30 derniers jours. Plus il est proche de 100 %, plus les scores sont homogènes.',
  'Progression : reprend sur une même ligne les pourcentages de groupement puis de score de la dynamique des performances 30 j/90 j.',
  'Dynamique des performances : compare les 30 derniers jours aux 90 derniers jours, qui incluent la période récente.',
  'Dans le comparatif, chaque point de la courbe est la moyenne d’une session sur les 90 derniers jours. La courbe donne le même poids visuel à chaque session, tandis que les moyennes 30 j/90 j restent calculées par série.',
  'Pour le groupement, une valeur plus basse signifie un groupement plus serré. Les groupements absents ou invalides sont ignorés sans retirer le score correspondant.',
];

/// Écran tableau de bord avec statistiques
class HomeScreen extends StatefulWidget {
  final SessionService? sessionService;
  final ServerWakeService? serverWakeService;

  const HomeScreen({
    super.key,
    this.sessionService,
    this.serverWakeService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SessionService _sessionService =
      widget.sessionService ?? SessionService();
  List<ShootingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = widget.serverWakeService ??
          Provider.of<ServerWakeService?>(context, listen: false);
      if (service != null) unawaited(service.wake());
    });
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _sessionService.getAllSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const AppBarTitle(
          icon: Icons.bar_chart,
          label: 'Synthèse',
        ),
        actions: [
          const HelpButton(
            title: 'Comprendre les statistiques',
            points: dashboardStatisticsHelpPoints,
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Règles & fondamentaux',
            onPressed: () => RulesBottomSheet.show(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DashboardTabView(
              sessions: _sessions,
              onRecordsChanged: _loadSessions,
            ),
    );
  }
}
