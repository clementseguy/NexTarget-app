# `flutter test` bloque sur des tests widget de `SessionForm` (NT-073)

> Document de suivi d'un défaut d'infrastructure de test découvert pendant les
> travaux NT-073. Non résolu, à traiter séparément avant de considérer NT-073
> comme définitivement terminé (voir Definition of Done).

## Symptôme

`flutter test` (suite complète ou fichier isolé) reste bloqué indéfiniment
(aucune sortie, aucun timeout par défaut) sur certains tests widget qui
construisent `SessionForm` (`lib/widgets/session_form.dart`) **ou**
`PlannedSessionWizard` (`lib/screens/wizard/planned_session_wizard.dart`). Le
blocage est total : aucun test suivant ne s'exécute tant que celui-ci n'est
pas interrompu manuellement.

Tests concernés, confirmés reproductibles (chacun hang **seul**, en isolation
complète, donc indépendamment de tout effet cumulatif d'une longue suite) :
- `test/session_form_caliber_prefill_test.dart` (plusieurs cas).
- `test/screens/planned_session_wizard_caliber_test.dart` — *« le wizard
  conserve le calibre prévu et laisse la saisie libre »*.
- `test/widgets/settings/default_caliber_setting_test.dart` — *« seule une
  suggestion sélectionnée est persistée »*.

**Facteur commun identifié avec certitude** : chacun de ces 3 tests combine
(a) une vraie box Hive (`Hive.init(tempDir)` + `Hive.openBox(...)`, pas de
mock) et (b) un widget qui construit `CaliberAutocompleteField`
(`RawAutocomplete`), avec un `tester.pump()` simple (pas de `pumpAndSettle`).
L'ordre écriture-Hive-avant-build ou écriture-déclenchée-par-interaction-après-
build ne change rien : les deux cas hang.

**Contre-preuve établie** : `test/widgets/caliber_autocomplete_field_test.dart`
construit `CaliberAutocompleteField` sans toucher à Hive du tout (aucun
`Hive.init`/`openBox`) et **passe instantanément** (2 tests, < 1s). Donc ni
`RawAutocomplete` seul, ni Hive seul, ne suffisent : c'est la combinaison des
deux dans un même test widget qui bloque.

## Ce qui a été essayé (2026-09-03)

1. **Écarté : contention machine.** Un émulateur Android + `flutter run`
   tournaient en tâche de fond (~70 min) au moment de la première
   observation. Arrêtés (`kill -9`) : le blocage persiste à l'identique.
2. **Écarté : cache de compilation.** `flutter clean` + `flutter pub get`
   puis relance : le blocage persiste (confirmé par un timeout de test qui
   échoue proprement après 2s, montrant que le test lui-même ne progresse
   pas, indépendamment du temps de recompilation).
3. **Écarté : lien avec la préférence `default_caliber`.** Un test de
   bisection écrivant une clé Hive *sans rapport* (`unrelated_key`) avant de
   construire `SessionForm` reproduit le même blocage. La logique NT-073
   (calibre par défaut, `pickInitialCaliber`, `PreferencesService`) n'est
   donc **pas en cause**.
4. **Écarté : `CaliberAutocompleteField` isolé.** Le widget d'autocomplétion
   seul, avec un `TextEditingController` pré-rempli, se construit
   instantanément dans un test dédié.
5. **Écarté : simple import.** Importer `session_form.dart` (donc toute sa
   chaîne de dépendances : `image_picker`, `file_picker`, `share_plus`,
   `ExerciseService`...) sans construire le widget, puis écrire dans Hive,
   passe instantanément.
6. **Logs `debugPrint` temporaires** ajoutés dans `SessionForm.initState`,
   `_loadExercises`, `build`, et `PreferencesService.getDefaultCaliber` (puis
   retirés) : **aucun ne s'affiche jamais**. Le blocage se produit donc avant
   toute exécution de code applicatif observable, sur la ligne du test qui
   suit un `Hive.box(...).put(...)` puis tente `tester.pumpWidget(...)` avec
   `SessionForm` dans l'arbre.
7. **Constat additionnel troublant** : après le timeout d'un test reproduisant
   le blocage, le `tearDown` (`Hive.close()`) du test suivant reste lui aussi
   bloqué plusieurs dizaines de secondes — cohérent avec une opération Hive
   restée réellement en suspens (deadlock), pas avec une simple lenteur.

## Hypothèse retenue

**`RawAutocomplete` (utilisé par `CaliberAutocompleteField`) combiné à une
vraie box Hive dans le même test widget.** Les hypothèses « plugin natif » et
« ordre put/build » ont toutes deux été écartées par contre-exemples directs
(voir ci-dessus). `RawAutocomplete` gère un `OverlayEntry`/`LayerLink` pour
afficher ses suggestions ; une hypothèse plausible est une interaction entre
la planification de frame de cet overlay et l'I/O fichier réelle de Hive
(non mockée) dans l'environnement `flutter test`, mais cela reste à confirmer
profilé/débuggé pour être certain.

Piste de vérification suivante, non menée : reproduire un cas minimal avec
uniquement `RawAutocomplete` (sans passer par `CaliberAutocompleteField`) +
une vraie box Hive, pour confirmer que le problème ne dépend pas non plus
d'un détail de `CaliberAutocompleteField` lui-même.

## Actions appliquées dans l'immédiat

- Un `timeout: const Timeout(Duration(seconds: 2))` a été ajouté sur les 3
  tests identifiés comme bloquants (`session_form_caliber_prefill_test.dart`,
  `planned_session_wizard_caliber_test.dart`,
  `default_caliber_setting_test.dart`) pour échouer vite au lieu de bloquer
  la CI/le poste de dev indéfiniment. Sans ce timeout, le test parent bloque
  **toute la suite** (aucun fichier suivant ne s'exécute).
- Le test original le plus complexe (deux `pumpForm` dans un seul
  `testWidgets`) a été scindé en tests plus petits et plus lisibles (un
  `pumpForm` par test), sans effet sur le blocage mais amélioration de
  lisibilité conservée.
- Tous les fichiers de diagnostic temporaires (`test/zz_*`) ont été supprimés ;
  aucune instrumentation de debug ne subsiste dans `lib/`.

## Statut

**Non résolu, périmètre confirmé plus large qu'initialement estimé : 3
fichiers de test impactés**, tous caractérisés par la combinaison
`RawAutocomplete` (via `CaliberAutocompleteField`) + vraie box Hive dans le
même test widget. Un timeout de 2s sur chacun limite l'impact (échec rapide
au lieu d'un blocage total de toute la suite) mais ne corrige pas la cause
racine et fait donc échouer 3 tests (constat volontairement accepté pour ne
pas bloquer l'avancement, voir échanges avec le demandeur du 2026-09-03). À
reprendre impérativement avant de considérer NT-073 comme répondant à sa
Definition of Done — `flutter test` doit passer intégralement (`AGENTS.md`).
