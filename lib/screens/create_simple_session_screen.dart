import 'package:flutter/material.dart';

import '../models/shooting_session.dart';
import '../services/session_service.dart';
import '../widgets/simple_session_form.dart';

class CreateSimpleSessionScreen extends StatelessWidget {
  final SimpleShootingSession? initialSession;
  final SessionService? sessionService;

  const CreateSimpleSessionScreen({
    super.key,
    this.initialSession,
    this.sessionService,
  });

  bool get isEdit => initialSession != null;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<SimpleSessionFormState>();
    SimpleShootingSession? pendingSession;
    final service = sessionService ?? SessionService();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEdit ? 'Modifier la session libre' : 'Nouvelle session libre'),
        actions: [
          IconButton(
            tooltip: 'Enregistrer la session libre',
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              if (!(formKey.currentState?.validateAndBuild() ?? false)) return;
              try {
                if (isEdit) {
                  await service.updateSession(pendingSession!);
                } else {
                  await service.addSession(pendingSession!);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session libre enregistrée')),
                );
                Navigator.of(context).pop();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erreur à l’enregistrement')),
                );
              }
            },
          ),
        ],
      ),
      body: SimpleSessionForm(
        key: formKey,
        initialSession: initialSession,
        onSave: (session) => pendingSession = session,
      ),
    );
  }
}
