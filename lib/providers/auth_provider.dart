import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/auth_session_exceptions.dart';
import '../services/logger.dart';

/// Provider pour la gestion d etat d authentification
///
/// Utilise ChangeNotifier pour notifier l UI des changements d etat
/// (isAuthenticated, currentUser, etc.)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  AuthProvider(this._authService);

  /// Exposé pour construire un AuthenticatedHttpClient depuis l'UI
  /// (ex. ServerCoachAnalysisService).
  AuthService get authService => _authService;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  /// Verifie au demarrage si l utilisateur a un token valide
  ///
  /// NT-048 : une panne réseau ne doit ni effacer les tokens locaux ni être
  /// traitée comme une session invalide ; elle se traduit ici par un statut
  /// "non authentifié" transitoire (le carnet reste utilisable hors ligne,
  /// et la prochaine vérification réussie restaure l'état connecté).
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasToken = await _authService.hasToken();

      if (hasToken) {
        final isValid = await _authService.isAuthenticated();

        if (isValid) {
          _currentUser = await _authService.getUserInfo();
          _isAuthenticated = true;
        } else {
          _isAuthenticated = false;
          _currentUser = null;
        }
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } on SessionExpiredException {
      _isAuthenticated = false;
      _currentUser = null;
    } on NetworkUnavailableException {
      _isAuthenticated = false;
      _currentUser = null;
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors de la vérification du statut', e);
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lance le flow OAuth Google (ouvre le navigateur externe)
  /// Le résultat sera traité via handleAuthCallback() quand le deep link arrive
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ouvre le navigateur, ne retourne pas de résultat immédiat
      await _authService.signInWithGoogle();

      // Note: _isLoading reste à true jusqu'à ce que handleAuthCallback() soit appelé
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors de l\'authentification Google', e);

      _isLoading = false;
      notifyListeners();

      rethrow;
    }
  }

  /// Traite le callback du deep link OAuth
  /// À appeler depuis le deep link handler dans main.dart
  Future<void> handleAuthCallback(Uri callbackUri) async {
    try {
      final result = await _authService.handleCallback(callbackUri);

      _currentUser = result;
      _isAuthenticated = true;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors du traitement du callback OAuth', e);

      _isAuthenticated = false;
      _currentUser = null;
      _isLoading = false;

      notifyListeners();

      rethrow;
    }
  }

  /// Deconnexion
  Future<void> logout() async {
    await _authService.logout();

    _isAuthenticated = false;
    _currentUser = null;

    notifyListeners();
  }

  /// Rafraichit les infos utilisateur
  ///
  /// NT-048 : seule une session réellement terminée (refresh invalide,
  /// expiré, révoqué ou rejoué) déclenche une déconnexion locale ; une panne
  /// réseau ou une erreur transitoire laisse les tokens et l'état intacts.
  Future<void> refreshUserInfo() async {
    if (!_isAuthenticated) return;

    try {
      _currentUser = await _authService.getUserInfo();
      notifyListeners();
    } on SessionExpiredException {
      await logout();
    } catch (e) {
      AppLogger.I.error(
          'AUTH: erreur lors du rafraîchissement des infos utilisateur', e);
    }
  }

  /// Met à jour le niveau d'expérience de l'utilisateur
  /// Appelle PATCH /users/me/profile puis rafraîchit _currentUser
  Future<void> updateExperienceLevel(String level) async {
    if (!_isAuthenticated) return;

    try {
      await _authService.updateProfile(experienceLevel: level);
      await refreshUserInfo();
    } on SessionExpiredException {
      await logout();
      rethrow;
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors de la mise à jour du niveau', e);
      rethrow;
    }
  }
}
