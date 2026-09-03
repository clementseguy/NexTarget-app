# Blocage Hive dans des tests widget de NT-073

> Diagnostic résolu le 2026-09-03 pendant la finalisation de NT-073.

## Symptôme initial

Trois tests widget restaient bloqués indéfiniment :

- `test/session_form_caliber_prefill_test.dart` ;
- `test/screens/planned_session_wizard_caliber_test.dart` ;
- `test/widgets/settings/default_caliber_setting_test.dart`.

Un timeout de secours de deux secondes avait temporairement été ajouté à ces
tests. Après expiration, le teardown pouvait lui aussi rester bloqué lors de
`Hive.close()`.

La première analyse attribuait le problème à la combinaison d'un
`RawAutocomplete` et d'une vraie box Hive. Cette hypothèse était trop large :
`RawAutocomplete` était seulement présent dans les widgets testés, mais ne
participait pas au deadlock.

## Cause racine

Les tests appelaient `await Hive.box(...).put(...)` directement dans le corps
d'un `testWidgets`, sur une box Hive adossée à un fichier. Le corps d'un test
widget s'exécute dans la zone fake-async de Flutter. L'écriture fichier différée
par Hive ne pouvait pas y progresser, donc la future de `put()` ne se terminait
jamais. Le widget n'était pas encore construit au moment du blocage.

Le teardown restait ensuite bloqué parce que `Hive.close()` attendait la même
file d'écriture inachevée.

Ce comportement et sa solution étaient déjà documentés dans les tests existants
`onboarding_screen_test.dart`, `session_coach_analysis_section_test.dart` et
`sessions_history_screen_test.dart`.

## Correction

- Les tests widget qui ont besoin d'une box utilisent une box Hive en mémoire,
  ouverte avec `bytes: Uint8List(0)`. Ils conservent ainsi le vrai contrat Hive
  sans effectuer d'I/O fichier dans la zone fake-async.
- Le test du wizard n'utilise plus Hive : le wizard modifie une session existante
  et ne consulte pas la préférence de calibre par défaut.
- Les timeouts de secours ont été retirés.
- La persistance fichier et la validation restent couvertes par les tests de
  service et de stockage, qui ne s'exécutent pas dans une zone fake-async de
  test widget.

Cette correction ne modifie ni `RawAutocomplete`, ni le comportement produit.
Elle sépare la vérification UI de l'I/O fichier et évite tout timer ou opération
Hive en attente à la fin des tests.
