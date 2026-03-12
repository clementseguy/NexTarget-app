import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: const Center(child: Text('Non connecté')),
      );
    }

    final displayName = user['display_name'] as String?;
    final email = user['email'] as String? ?? '';
    final avatarUrl = user['avatar_url'] as String?;
    final experienceLevel = user['experience_level'] as String?;
    final provider = user['provider'] as String? ?? '';
    final createdAt = user['created_at'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          // Avatar + nom + email
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      _initials(displayName, email),
                      style: TextStyle(fontSize: 28, color: colorScheme.onPrimary),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          if (displayName != null && displayName.isNotEmpty)
            Center(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),

          const SizedBox(height: 28),

          // Niveau d'expérience
          Text(
            'Niveau d\'expérience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'beginner', label: Text('Débutant')),
              ButtonSegment(value: 'advanced', label: Text('Confirmé')),
              ButtonSegment(value: 'expert', label: Text('Expert')),
            ],
            selected: experienceLevel != null ? {experienceLevel} : {},
            emptySelectionAllowed: true,
            onSelectionChanged: (selected) async {
              if (selected.isEmpty) return;
              try {
                await authProvider.updateExperienceLevel(selected.first);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur : impossible de mettre à jour le niveau'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 28),

          // Informations
          Text(
            'Informations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Membre depuis',
                    value: _formatDate(createdAt),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Connexion via',
                    value: _capitalizeProvider(provider),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Bouton déconnexion
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _initials(String? displayName, String email) {
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat.yMMMd('fr_FR').format(date);
    } catch (e) {
      print('[PROFILE] Erreur formatage date "$isoDate": $e');
      return '—';
    }
  }

  String _capitalizeProvider(String provider) {
    if (provider.isEmpty) return '—';
    return provider[0].toUpperCase() + provider.substring(1);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
