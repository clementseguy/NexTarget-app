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
      print('[AUTH_PROVIDER] Erreur checkAuthStatus: $e');
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lance le flow OAuth Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      
      _currentUser = await _authService.getUserInfo();
      _isAuthenticated = true;
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      print('[AUTH_PROVIDER] Erreur signInWithGoogle: $e');
      
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
      print('[AUTH_PROVIDER] Erreur refreshUserInfo: $e');
      await logout();
    }
  }
}
