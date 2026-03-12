import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

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

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  /// Verifie au demarrage si l utilisateur a un token valide
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
    } catch (e) {
      print('[AUTH] Erreur lors de la vérification du statut: $e');
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
      print('[AUTH] Erreur lors de l\'authentification Google: $e');
      
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
      print('[AUTH] Erreur lors du traitement du callback OAuth: $e');
      
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
  Future<void> refreshUserInfo() async {
    if (!_isAuthenticated) return;

    try {
      _currentUser = await _authService.getUserInfo();
      notifyListeners();
    } catch (e) {
      print('[AUTH] Erreur lors du rafraîchissement des infos utilisateur: $e');
      await logout();
    }
  }

  /// Met à jour le niveau d'expérience de l'utilisateur
  /// Appelle PATCH /users/me/profile puis rafraîchit _currentUser
  Future<void> updateExperienceLevel(String level) async {
    if (!_isAuthenticated) return;

    try {
      await _authService.updateProfile(experienceLevel: level);
      await refreshUserInfo();
    } catch (e) {
      print('[AUTH] Erreur lors de la mise à jour du niveau: $e');
      rethrow;
    }
  }
}
