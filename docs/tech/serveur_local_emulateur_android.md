# Serveur local avec l'émulateur Android

Cette configuration permet à un build Flutter debug d'utiliser le serveur
NexTarget lancé sur la machine hôte, y compris pendant le flow OAuth Google.

## 1. Configurer et lancer le serveur

Dans `NexTarget-server`, configurer au minimum les variables de `.env` :

```dotenv
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REDIRECT_URI=http://localhost:8000/auth/google/callback
JWT_SECRET_KEY=...
MISTRAL_API_KEY=...
```

L'URI suivante doit également être déclarée comme URI de redirection autorisée
dans le client OAuth Google :

```text
http://localhost:8000/auth/google/callback
```

Puis lancer le serveur :

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Vérifier son état depuis la machine hôte :

```bash
curl http://localhost:8000/health
```

## 2. Relier l'émulateur au serveur

Avec l'émulateur démarré :

```bash
adb reverse tcp:8000 tcp:8000
adb reverse --list
```

Le reverse permet à l'app et au navigateur Android d'atteindre le serveur de la
machine hôte via `127.0.0.1:8000` ou `localhost:8000`. Il évite notamment que le
callback OAuth Google reste bloqué dans l'émulateur.

Le reverse doit être réappliqué après un redémarrage de l'émulateur.

## 3. Lancer l'app

Dans `NexTarget-app` :

```bash
flutter run \
  --dart-define=NEXTARGET_SERVER_URL=http://127.0.0.1:8000
```

`NEXTARGET_SERVER_URL` surcharge uniquement l'URL du serveur. Sans cette option,
l'app continue d'utiliser l'URL Render définie dans `assets/config.yaml`.

Le trafic HTTP clair n'est autorisé que par le manifeste Android `debug`. Un
build release continue donc d'exiger HTTPS.

## Diagnostic rapide

```bash
adb shell curl http://127.0.0.1:8000/health
```

Si `curl` n'est pas présent dans l'image Android, ouvrir
`http://localhost:8000/docs` dans le navigateur de l'émulateur.

Si Google affiche `redirect_uri_mismatch`, vérifier la valeur exacte de
`GOOGLE_REDIRECT_URI` et sa déclaration dans Google Cloud Console.
