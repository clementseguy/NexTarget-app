import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';

/// Ecran de connexion avec authentification Google OAuth2
///
/// Affiche:
/// - Bouton "Se connecter avec Google" (OAuth2 flow)
/// - Bouton "Continuer sans compte" (si auth.enabled=false dans config)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      if (!context.mounted) return;

      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'authentification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSkip(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authEnabled = AppConfig.I.authEnabled;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/app_logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  'NexTarget',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connecte-toi pour synchroniser tes donnees',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton.icon(
                    onPressed: () => _handleGoogleSignIn(context),
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter avec Google'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  if (!authEnabled) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _handleSkip(context),
                      child: const Text('Continuer sans compte'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
