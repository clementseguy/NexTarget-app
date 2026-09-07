import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/auth_session_exceptions.dart';
import '../services/logger.dart';

enum AuthStatus { verifying, authenticated, unauthenticated }

/// Provider pour la gestion d etat d authentification
///
/// Utilise ChangeNotifier pour notifier l UI des changements d etat
/// (isAuthenticated, currentUser, etc.)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.verifying;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  AuthProvider(this._authService) {
    _authService.onSessionInvalidated = _handleSessionInvalidated;
  }

  /// Exposé pour construire un AuthenticatedHttpClient depuis l'UI
  /// (ex. ServerCoachAnalysisService).
  AuthService get authService => _authService;

  AuthStatus get status => _status;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;
  bool get isVerificationPending => _status == AuthStatus.verifying;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  void _setAuthenticated(Map<String, dynamic> user) {
    _currentUser = user;
    _status = AuthStatus.authenticated;
  }

  void _setUnauthenticated() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
  }

  void _handleSessionInvalidated() {
    _isLoading = false;
    _setUnauthenticated();
    notifyListeners();
  }

  /// Verifie au demarrage si l utilisateur a un token valide
  ///
  /// Une panne réseau ne doit ni effacer les tokens locaux ni être traitée
  /// comme une session invalide. Un profil en cache permet de rester connecté
  /// hors ligne ; sans cache, l'état reste en vérification jusqu'à une action
  /// explicite de l'utilisateur.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    Map<String, dynamic>? cachedUser;

    try {
      final hasToken = await _authService.hasToken();

      if (hasToken) {
        cachedUser = await _authService.readCachedUser();
        final user = await _authService.getUserInfo();
        _setAuthenticated(user);
      } else {
        _setUnauthenticated();
      }
    } on SessionExpiredException {
      _setUnauthenticated();
    } on NetworkUnavailableException {
      if (cachedUser != null) {
        _setAuthenticated(cachedUser);
      } else {
        _currentUser = null;
        _status = AuthStatus.verifying;
      }
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors de la vérification du statut', e);
      _setUnauthenticated();
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

      _setAuthenticated(result);
      _isLoading = false;

      notifyListeners();
    } on SessionExpiredException catch (e) {
      AppLogger.I.error('AUTH: erreur lors du traitement du callback OAuth', e);

      _setUnauthenticated();
      _isLoading = false;

      notifyListeners();

      rethrow;
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors du traitement du callback OAuth', e);

      // Une panne transitoire pendant un nouveau flow OAuth ne doit pas
      // déconnecter une éventuelle session locale déjà valide.
      _isLoading = false;
      notifyListeners();

      rethrow;
    }
  }

  /// Deconnexion
  Future<void> logout() async {
    await _authService.logout();

    _setUnauthenticated();

    notifyListeners();
  }

  Future<void> handleConfirmedInvalidation() async {
    await _authService.invalidateSession();
  }

  /// Rafraichit les infos utilisateur
  ///
  /// NT-048 : seule une session réellement terminée (refresh invalide,
  /// expiré, révoqué ou rejoué) déclenche une déconnexion locale ; une panne
  /// réseau ou une erreur transitoire laisse les tokens et l'état intacts.
  Future<void> refreshUserInfo() async {
    if (!isAuthenticated) return;

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
    if (!isAuthenticated) return;

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
