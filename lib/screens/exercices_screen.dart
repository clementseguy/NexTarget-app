import 'package:flutter/material.dart';
import '../widgets/goals_at_glance_card.dart';
import '../widgets/exercises_at_glance_card.dart';
import '../widgets/help_button.dart';

class ExercicesScreen extends StatefulWidget {
  const ExercicesScreen({super.key});

  @override
  State<ExercicesScreen> createState() => _ExercicesScreenState();
}

class _ExercicesScreenState extends State<ExercicesScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Exercices & Objectifs'),
        actions: const [
          HelpButton(
            title: 'Exercices & Objectifs',
            points: [
              'Les objectifs sont des cibles chiffrées (score moyen, groupement…) suivies automatiquement à partir de vos sessions.',
              'Les exercices sont des entraînements types (stand ou maison) avec consignes ; reliez-les à vos objectifs.',
              'Depuis un exercice de stand, planifiez directement une session prévue.',
              'Touchez une carte pour ouvrir la liste complète correspondante.',
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GoalsAtGlanceCard(),
          const SizedBox(height: 16),
          const ExercisesAtGlanceCard(),
        ],
      ),
    );
  }
}