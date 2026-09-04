# Spécifications Backend OAuth pour NexTarget

## ⚠️ Problème actuel

Le backend retourne le JSON directement au lieu de rediriger vers l'app avec le custom URL scheme.

**Comportement actuel (incorrect) :**
```
GET /auth/google/callback?code=...&state=...
→ Retourne: {"access_token": "JWT...", "email": "user@gmail.com"}
```

**Comportement attendu (correct) :**
```
GET /auth/google/callback?code=...&state=...
→ HTTP 302 Redirect vers: nextarget://callback#access_token=JWT&email=user@gmail.com&provider=google
```

---

## Endpoint 1: `/auth/google/start`

### Request
```http
GET /auth/google/start
```

### Response (200 OK)
```json
{
  "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=https://nextarget-server.onrender.com/auth/google/callback&response_type=code&scope=email%20profile&state=RANDOM_STATE_TOKEN",
  "state": "RANDOM_STATE_TOKEN"
}
```

**Notes :**
- `state` : Token aléatoire pour protection CSRF (à vérifier dans le callback)
- `redirect_uri` : Doit pointer vers le backend `/auth/google/callback`
- `scope` : Minimum `email profile`

---

## Endpoint 2: `/auth/google/callback` ⚠️ À CORRIGER

### Request (de Google)
```http
GET /auth/google/callback?code=GOOGLE_AUTH_CODE&state=RANDOM_STATE_TOKEN
```

### Traitement backend
1. Vérifier que `state` correspond à celui envoyé dans `/start`
2. Échanger le `code` contre un access_token Google via `https://oauth2.googleapis.com/token`
3. Récupérer les infos utilisateur Google (`email`, `name`) via `https://www.googleapis.com/oauth2/v2/userinfo`
4. Créer ou récupérer l'utilisateur en base de données
5. Générer un JWT NexTarget avec payload : `{user_id, email, provider: "google"}`
6. **REDIRIGER** (et non retourner du JSON) vers l'app

### Response actuelle (INCORRECT ❌)
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "user@example.com",
  "provider": "google"
}
```

### Response attendue (CORRECT ✅)
```http
HTTP/1.1 302 Found
Location: nextarget://callback#access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...&email=user@example.com&provider=google
```

**⚠️ IMPORTANT : Utiliser le fragment (#) et non la query (?) pour le token**

Raison : Le fragment (#) n'est pas envoyé au serveur dans les logs. La query (?) serait visible dans les logs serveur.

---

## Exemple de code backend (Node.js/Express)

```javascript
// Route: /auth/google/callback
app.get('/auth/google/callback', async (req, res) => {
  const { code, state } = req.query;
  
  // 1. Vérifier le state (CSRF protection)
  if (!verifyState(state)) {
    return res.status(400).json({ error: 'Invalid state' });
  }
  
  // 2. Échanger le code contre un access_token Google
  const googleTokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      code,
      client_id: process.env.GOOGLE_CLIENT_ID,
      client_secret: process.env.GOOGLE_CLIENT_SECRET,
      redirect_uri: 'https://nextarget-server.onrender.com/auth/google/callback',
      grant_type: 'authorization_code'
    })
  });
  const { access_token: googleAccessToken } = await googleTokenResponse.json();
  
  // 3. Récupérer les infos utilisateur
  const userInfoResponse = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
    headers: { Authorization: `Bearer ${googleAccessToken}` }
  });
  const { email, name } = await userInfoResponse.json();
  
  // 4. Créer ou récupérer l'utilisateur en DB
  const user = await findOrCreateUser({ email, name, provider: 'google' });
  
  // 5. Générer un JWT NexTarget
  const jwtToken = jwt.sign(
    { user_id: user.id, email: user.email, provider: 'google' },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
  
  // 6. ✅ REDIRIGER vers l'app (et non retourner du JSON)
  const callbackUrl = `nextarget://callback#access_token=${jwtToken}&email=${encodeURIComponent(email)}&provider=google`;
  res.redirect(callbackUrl);
});
```

**Note Python/Flask :**
```python
from flask import redirect

@app.route('/auth/google/callback')
def google_callback():
    # ... (étapes 1-5)
    
    # 6. Rediriger vers l'app
    callback_url = f"nextarget://callback#access_token={jwt_token}&email={email}&provider=google"
    return redirect(callback_url, code=302)
```

---

## Endpoint 3: `/users/me`

### Request
```http
GET /users/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Response (200 OK)
```json
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  "provider": "google",
  "created_at": "2025-10-15T10:30:00Z"
}
```

### Response (401 Unauthorized) - Token invalide ou expiré
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

---

## Testing

### Test manuel avec curl

1. **Obtenir l'URL OAuth :**
```bash
curl https://nextarget-server.onrender.com/auth/google/start
```

2. **Ouvrir l'URL dans un navigateur et s'authentifier**

3. **Vérifier que le navigateur redirige vers `nextarget://callback#access_token=...`**

Si tu vois du JSON au lieu d'une redirection → **le backend est mal configuré**

### Test avec l'app Flutter

Logs attendus dans la console :
```
[AUTH] Demande de l URL OAuth au serveur...
[AUTH] Ouverture du navigateur in-app...
[AUTH] Callback intercepte
[AUTH] Authentification reussie et token stocke
```

Si tu vois `User canceled login` → Le backend ne redirige pas correctement

---

## Sécurité

✅ **À faire :**
- Utiliser HTTPS (pas HTTP) pour le backend
- Valider le `state` dans le callback (protection CSRF)
- Token JWT dans le fragment (#) et non la query (?)
- JWT avec expiration (ex: 30 jours)
- Vérifier l'email Google si besoin de whitelisting

❌ **À ne pas faire :**
- Retourner le JWT dans un JSON au lieu de rediriger
- Utiliser la query (?) pour le token (visible dans les logs)
- Accepter n'importe quel `state` sans validation

---

## Checklist Backend

- [ ] `/auth/google/start` retourne `auth_url` et `state`
- [ ] `/auth/google/callback` **redirige (302)** vers `nextarget://callback#access_token=...`
- [ ] Token JWT dans le **fragment (#)** et non la query (?)
- [ ] `/users/me` valide le JWT et retourne les infos utilisateur
- [ ] HTTPS activé sur le backend
- [ ] State CSRF validé dans le callback

---

**Contact :** Si le backend est géré par une autre personne, envoie-lui ce document !
