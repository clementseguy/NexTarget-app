# OAuth Mobile - Implémentation Complète

## ✅ Solution Implémentée

L'authentification OAuth mobile fonctionne désormais avec un flow simplifié où le **backend gère entièrement le flow OAuth2** et redirige vers l'app mobile avec le token.

**URL Backend** : `https://nextarget-server.onrender.com`

---

## Ancien Problème (Résolu)

L'authentification Google OAuth depuis l'application mobile échouait car le backend utilisait un `redirect_uri` web au lieu d'un `redirect_uri` mobile avec custom URL scheme.

## Workflow OAuth Actuel

```
1. App mobile → GET /auth/google/start
2. Backend → Génère URL OAuth avec redirect_uri=https://nextarget-server.onrender.com/auth/google/callback
3. App ouvre navigateur in-app avec cette URL
4. Utilisateur s'authentifie sur Google
5. Google redirige vers https://nextarget-server.onrender.com/auth/google/callback
6. ❌ PROBLÈME : L'app mobile ne peut pas intercepter cette URL web
7. L'app considère que l'utilisateur a annulé (CANCELED)
```

## ✅ Workflow OAuth Actuel (Implémenté)

```
1. App mobile → Ouvre https://nextarget-server.onrender.com/auth/google/login
2. Backend → Gère entièrement le flow OAuth2 avec Google
3. Utilisateur s'authentifie sur Google (écran géré par backend)
4. Backend → Génère un JWT et redirige vers nextarget://callback?token=XYZ
5. ✅ App mobile intercepte le deep link via flutter_web_auth_2
6. App extrait le token des query parameters
7. App stocke le token dans flutter_secure_storage
8. App récupère les infos utilisateur avec le token
9. ✅ Navigation automatique vers le dashboard
```

**Avantages** :
- 🎯 Flow simplifié côté mobile
- 🔒 Backend contrôle entièrement la sécurité OAuth
- 📱 Fonctionne sur Android et iOS
- ✅ Gestion d'erreur claire via `?error=...`

## Étape Erronnée

**Endpoint `/auth/google/start`** :
- ❌ Utilise un `redirect_uri` web fixe
- ❌ N'accepte pas de paramètre `redirect_uri` personnalisé

## Logs Actuels

```
[AUTH] 🌐 URL OAuth reçue: https://accounts.google.com/o/oauth2/v2/auth?
  client_id=421758296135-f77iuo8452kojjqqp36gotnll15m1s1p.apps.googleusercontent.com
  &redirect_uri=https%3A%2F%2Fnextarget-server.onrender.com%2Fauth%2Fgoogle%2Fcallback  ← PROBLÈME
  &response_type=code
  ...

[AUTH] 📱 Callback scheme attendu: nextarget
[AUTH] Erreur : PlatformException(CANCELED, User canceled login, null, null)
```

## ✅ Implémentation Backend Requise

### Endpoint Principal : `/auth/google/login`

**Route** : `GET https://nextarget-server.onrender.com/auth/google/login`

**Comportement** :
1. Redirige vers Google OAuth pour authentification
2. Après succès, génère un JWT
3. Redirige vers `nextarget://callback?token=<JWT>`
4. En cas d'erreur : `nextarget://callback?error=<message>`

**Exemple Python/Flask** :
```python
@app.route('/auth/google/login')
def google_login():
    # Initialiser le flow OAuth2
    flow = Flow.from_client_config(
        client_config=GOOGLE_CLIENT_CONFIG,
        scopes=['openid', 'email', 'profile'],
        redirect_uri='https://nextarget-server.onrender.com/auth/google/callback'
    )
    
    authorization_url, state = flow.authorization_url(
        access_type='offline',
        include_granted_scopes='true'
    )
    
    session['state'] = state
    return redirect(authorization_url)

@app.route('/auth/google/callback')
def google_callback():
    try:
        # Échanger le code contre un token
        flow = Flow.from_client_config(
            client_config=GOOGLE_CLIENT_CONFIG,
            scopes=['openid', 'email', 'profile'],
            redirect_uri='https://nextarget-server.onrender.com/auth/google/callback',
            state=session['state']
        )
        flow.fetch_token(authorization_response=request.url)
        
        # Récupérer les infos utilisateur
        credentials = flow.credentials
        user_info = get_google_user_info(credentials.token)
        
        # Créer/mettre à jour l'utilisateur en DB
        user = create_or_update_user(user_info)
        
        # Générer un JWT
        jwt_token = generate_jwt({
            'user_id': user.id,
            'email': user.email
        })
        
        # Rediriger vers l'app mobile
        return redirect(f'nextarget://callback?token={jwt_token}')
        
    except Exception as e:
        return redirect(f'nextarget://callback?error={str(e)}')
```

### Configuration Google Cloud

**URI de redirection autorisés** :
```
https://nextarget-server.onrender.com/auth/google/callback
```

Note : `nextarget://callback` n'a PAS besoin d'être dans Google Cloud car c'est le backend qui redirige, pas Google directement.

## ✅ Implémentation App Mobile (Fait)

### AuthService

```dart
Future<Map<String, dynamic>> signInWithGoogle() async {
  // URL directe du backend qui gère tout le flow OAuth2
  final authUrl = '$_authBaseUrl/auth/google/login';
  
  print('[AUTH] 🚀 Ouverture du flow OAuth: $authUrl');
  
  // Ouvre le navigateur et attend le callback
  final resultUrl = await FlutterWebAuth2.authenticate(
    url: authUrl,
    callbackUrlScheme: _callbackScheme, // "nextarget"
  );
  
  final uri = Uri.parse(resultUrl);
  
  // Extraire token ou error des query parameters
  final token = uri.queryParameters['token'];
  final error = uri.queryParameters['error'];
  
  if (error != null) {
    throw Exception('Erreur d\'authentification: $error');
  }
  
  if (token == null) {
    throw Exception('Token manquant');
  }
  
  // Stocker le token en sécurité
  await _storage.write(key: 'jwt_token', value: token);
  
  // Récupérer les infos utilisateur
  final userInfo = await getUserInfo();
  
  return {
    'access_token': token,
    'email': userInfo['email'],
    'provider': 'google',
  };
}
```

## Configuration App Mobile (Déjà Fait)

### Android (`AndroidManifest.xml`)
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="nextarget"/>
</intent-filter>
```

### Config (`config.yaml`)
```yaml
auth:
  callback_scheme: "nextarget"
```

## Tests de Validation

Après correction backend :

1. Lancer l'app mobile
2. Cliquer sur "Se connecter avec Google"
3. Sélectionner un compte Google
4. Cliquer sur "Continue" dans l'écran de consentement
5. ✅ L'app doit automatiquement revenir et afficher l'écran d'accueil connecté

**Logs attendus** :
```
[AUTH] 🌐 URL OAuth reçue: ...&redirect_uri=nextarget%3A%2F%2Fcallback...
[AUTH] ✅ Callback reçu: nextarget://callback#access_token=...
[AUTH_PROVIDER] ✅ Authentification Google réussie
[AUTH_PROVIDER] 👤 Utilisateur connecté: user@example.com
[AUTH_GATE] ✅ Navigation vers l'application
```

## Références

- Custom URL Schemes Android : https://developer.android.com/training/app-links/deep-linking
- flutter_web_auth_2 : https://pub.dev/packages/flutter_web_auth_2
- Google OAuth Mobile : https://developers.google.com/identity/protocols/oauth2/native-app
