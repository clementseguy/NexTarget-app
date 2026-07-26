import 'package:flutter/material.dart';
import '../widgets/app_bar_title.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const AppBarTitle(
          icon: Icons.school,
          label: 'Coach',
        ),
      ),
      body: Center(child: Text('Coming soon', style: TextStyle(fontSize: 24))),
    );
  }
}
