# Compte et Coach IA

## Compte optionnel

Le carnet, les sessions, statistiques, objectifs, exercices, préférences et sauvegardes fonctionnent sans compte et hors ligne. Le compte Google est nécessaire uniquement pour le profil distant et le Coach IA.

Le flux de connexion est délégué à NexTarget-server : l'app demande une URL Google, ouvre le navigateur externe, reçoit `nextarget://callback?token=...`, échange ce jeton de callback contre une paire access/refresh et stocke la paire dans le stockage sécurisé.

L'access token est renouvelé avant expiration. Les appels concurrents partagent un seul renouvellement. Après un `401`, une seule rotation et une seule répétition de la requête sont tentées. Une panne réseau ne supprime pas la session locale ; un refresh invalide, expiré, révoqué ou rejoué exige une nouvelle connexion.

La déconnexion tente de révoquer le refresh token côté serveur puis efface toujours les jetons locaux, même si le réseau est indisponible.

Le profil affiche les informations fournies par le serveur. L'app permet actuellement de modifier le niveau d'expérience ; l'édition du nom n'est pas exposée.

## Coach connecté uniquement

Une session détaillée réalisée peut être envoyée à `POST /coach/analyze-session` avec son arme, son calibre, ses séries, sa synthèse et la variante de ton choisie. Le serveur construit le prompt et appelle Mistral ; aucune clé ni aucun prompt complet ne réside dans l'app.

Les tons Neutre et Cool se choisissent uniquement dans Paramètres. La réponse est affichée en Markdown et enregistrée dans la session. Sans compte, hors réseau, avec une session expirée ou pour une session libre, l'app bloque l'appel avec un état adapté sans rendre le carnet indisponible.
