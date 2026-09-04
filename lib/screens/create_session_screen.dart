import 'package:flutter/material.dart';
import '../widgets/session_form.dart';
import '../models/shooting_session.dart';

import '../services/session_service.dart';
import '../interfaces/session_photo_service_interface.dart';

class CreateSessionScreen extends StatelessWidget {
  final Map<String, dynamic>? initialSessionData;
  final bool isEdit;
  final SessionService? sessionService;
  final ISessionPhotoService? photoService;
  final SessionDuplicationDraft? duplicationDraft;
  const CreateSessionScreen({
    super.key,
    this.initialSessionData,
    this.isEdit = false,
    this.sessionService,
    this.photoService,
    this.duplicationDraft,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<SessionFormState>();
    final service = sessionService ?? SessionService();
    ShootingSession? pendingSession; // tampon local avant sauvegarde
    return StatefulBuilder(
      builder: (ctx, setLocalState) {
        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Modifier session' : 'Nouvelle session'),
            actions: [
              IconButton(
                tooltip: 'Enregistrer',
                icon: Icon(Icons.save_outlined),
                onPressed: () async {
                  if (pendingSession == null) {
                    final state = formKey.currentState;
                    if (state == null) return;
                    final ok = state.validateAndBuild();
                    if (!ok) return;
                  }
                  try {
                    final s = pendingSession!;
                    if (isEdit) {
                      await service.updateSession(s);
                    } else if (duplicationDraft != null) {
                      await service.saveDuplication(
                        draft: duplicationDraft!,
                        editedCopy: s,
                      );
                    } else {
                      await service.addSession(s);
                    }
                    formKey.currentState?.markSaved();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Session enregistrée')),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur à l\'enregistrement')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SessionForm(
              key: formKey,
              initialSessionData: initialSessionData,
              isEdit: isEdit,
              preserveInitialCaliber: duplicationDraft != null,
              photoService: photoService,
              onSave: (session) {
                // Session valide retournée par le formulaire
                pendingSession = session;
              },
            ),
          ),
        );
      },
    );
  }
}
