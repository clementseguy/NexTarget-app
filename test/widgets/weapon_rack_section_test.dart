import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/weapon_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/services/weapon_service.dart';
import 'package:tir_sportif/widgets/settings/weapon_rack_section.dart';

class _MemWeaponRepo implements WeaponRepository {
  final List<Weapon> list = [];
  @override
  Future<void> clear() async => list.clear();
  @override
  Future<void> delete(String id) async => list.removeWhere((w) => w.id == id);
  @override
  Future<List<Weapon>> getAll() async => List.of(list);
  @override
  Future<void> put(Weapon weapon) async {
    list.removeWhere((w) => w.id == weapon.id);
    list.add(weapon);
  }
}

class _MemSessionRepo implements SessionRepository {
  final List<ShootingSession> sessions = [];
  @override
  Future<void> clearAll() async => sessions.clear();
  @override
  Future<void> delete(int id) async => sessions.removeWhere((s) => s.id == id);
  @override
  // Clone (comme HiveSessionRepository) : muter un élément retourné par
  // getAll() ne doit jamais affecter l'état persistant avant update().
  Future<List<ShootingSession>> getAll() async =>
      sessions.map((s) => ShootingSession.fromMap(s.toMap())).toList();
  @override
  Future<int> insert(ShootingSession session) async {
    session.id = sessions.length + 1;
    sessions.add(session);
    return session.id!;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) sessions[idx] = session;
    return false;
  }
}

Future<void> _pump(WidgetTester tester, WeaponService service) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: WeaponRackSection(weaponService: service)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WeaponRackSection (NT-008)', () {
    testWidgets('affiche un message quand le râtelier est vide', (tester) async {
      final service = WeaponService(weaponRepository: _MemWeaponRepo(), sessionRepository: _MemSessionRepo());
      await _pump(tester, service);

      expect(find.text('Aucune arme enregistrée.'), findsOneWidget);
    });

    testWidgets("ajouter une arme l'affiche dans la liste", (tester) async {
      final service = WeaponService(weaponRepository: _MemWeaponRepo(), sessionRepository: _MemSessionRepo());
      await _pump(tester, service);

      await tester.enterText(find.byType(TextField), 'Glock 17');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Glock 17'), findsOneWidget);
      expect(find.text('Aucune arme enregistrée.'), findsNothing);
    });

    testWidgets('ajouter un doublon normalisé affiche une erreur et ne duplique pas', (tester) async {
      final service = WeaponService(weaponRepository: _MemWeaponRepo(), sessionRepository: _MemSessionRepo());
      await _pump(tester, service);

      await tester.enterText(find.byType(TextField), 'Glock 17');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  glock 17  ');
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Une arme porte déjà ce nom dans le râtelier.'), findsOneWidget);
      expect(find.text('Glock 17'), findsOneWidget); // une seule occurrence
    });

    testWidgets('supprimer une arme demande confirmation puis la retire', (tester) async {
      final weaponRepo = _MemWeaponRepo();
      final sessionRepo = _MemSessionRepo();
      final service = WeaponService(weaponRepository: weaponRepo, sessionRepository: sessionRepo);
      await service.addWeapon('Glock 17');
      await sessionRepo.insert(ShootingSession(weapon: 'Glock 17', caliber: '9mm', series: const []));

      await _pump(tester, service);
      expect(find.text('Glock 17'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text("Supprimer l'arme"), findsOneWidget);

      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Glock 17'), findsNothing);
      expect(find.text('Aucune arme enregistrée.'), findsOneWidget);
      // La session existante n'est pas modifiée par la suppression.
      expect(sessionRepo.sessions.single.weapon, 'Glock 17');
    });

    testWidgets('annuler la suppression conserve l\'arme', (tester) async {
      final service = WeaponService(weaponRepository: _MemWeaponRepo(), sessionRepository: _MemSessionRepo());
      await service.addWeapon('Glock 17');

      await _pump(tester, service);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Glock 17'), findsOneWidget);
    });

    testWidgets('renommer une arme demande confirmation puis met à jour la liste et les sessions', (tester) async {
      final weaponRepo = _MemWeaponRepo();
      final sessionRepo = _MemSessionRepo();
      final service = WeaponService(weaponRepository: weaponRepo, sessionRepository: sessionRepo);
      await service.addWeapon('CZ 75');
      await sessionRepo.insert(ShootingSession(weapon: 'CZ 75', caliber: '9mm', series: const []));

      await _pump(tester, service);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'CZ 75 SP-01 Shadow');
      await tester.tap(find.text('Renommer'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmer le renommage'), findsOneWidget);
      await tester.tap(find.text('Confirmer'));
      await tester.pumpAndSettle();

      expect(find.text('CZ 75 SP-01 Shadow'), findsOneWidget);
      expect(sessionRepo.sessions.single.weapon, 'CZ 75 SP-01 Shadow');
    });
  });
}
