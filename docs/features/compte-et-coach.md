# Compte et Coach IA

## Compte optionnel

Le carnet, les sessions, statistiques, objectifs, exercices, préférences et sauvegardes fonctionnent sans compte et hors ligne. Le compte Google est nécessaire uniquement pour le profil distant et le Coach IA.

Le flux de connexion est délégué à NexTarget-server : l'app demande une URL Google, ouvre le navigateur externe, reçoit `nextarget://callback?token=...`, échange ce jeton de callback contre une paire access/refresh et stocke la paire dans le stockage sécurisé.

L'access token est renouvelé avant expiration. Les appels concurrents partagent un seul renouvellement. Après un `401`, une seule rotation et une seule répétition de la requête sont tentées. Une panne réseau ne supprime pas la session locale ; un refresh invalide, expiré, révoqué ou rejoué exige une nouvelle connexion.

La déconnexion tente de révoquer le refresh token côté serveur puis efface toujours les jetons locaux, même si le réseau est indisponible.

Les écrans Auth, Profil et Coach partagent une traduction des erreurs réseau en sept familles : hors connexion/DNS, délai dépassé, service indisponible, limitation de débit, session invalide, requête invalide et erreur inattendue. Les détails techniques restent dans les journaux. Une erreur transitoire propose « Réessayer » pour la seule opération concernée et ne supprime jamais les jetons ; seule une invalidation confirmée propose « Se reconnecter ».

Le profil affiche les informations fournies par le serveur. L'app permet actuellement de modifier le niveau d'expérience ; l'édition du nom n'est pas exposée.

L'état de compte est porté uniquement par `AuthProvider` : vérification,
connecté avec un profil exploitable, ou non connecté. Un profil valide est mis
en cache dans le stockage sécurisé pour conserver l'affichage hors ligne. Une
paire de jetons moderne sans profil en cache reste en « Connexion à vérifier »
jusqu'à une action explicite « Réessayer » ; le Coach demeure alors inactif.
Un ancien `jwt_token` isolé est supprimé au premier démarrage, sans toucher aux
données du carnet. Toute invalidation confirmée est diffusée immédiatement aux
Paramètres, au Profil et au Coach.

## Coach connecté uniquement

Une session détaillée réalisée peut être envoyée à `POST /coach/analyze-session` avec son arme, son calibre, ses séries, sa synthèse et la variante de ton choisie. Le serveur construit le prompt et appelle Mistral ; aucune clé ni aucun prompt complet ne réside dans l'app.

Si la session référence un exercice personnel, l'app joint ponctuellement un
instantané limité à son identifiant, son nom, sa provenance `personal`, sa
description et ses consignes. Elle transmet séparément la réalisation déclarée,
le suivi du protocole (`yes`, `partially` ou `no`) et le commentaire de la
tentative. Les informations de catalogue, de plan, d'objectifs, de priorité,
d'équipement, de durée et de difficulté ne sont pas envoyées pour ce débrief.
L'instantané n'est ni synchronisé vers le catalogue ni persisté par ce contrat.
Le débrief l'identifie comme exercice personnel hors plan de formation et ne
l'évalue qu'avec la session, ces déclarations et les commentaires, sans critère
de réussite métier.

Les tons Neutre et Cool se choisissent uniquement dans Paramètres. La réponse est affichée en Markdown et enregistrée dans la session. Sans compte, hors réseau, avec une session expirée ou pour une session libre, l'app bloque l'appel avec un état adapté sans rendre le carnet indisponible.
