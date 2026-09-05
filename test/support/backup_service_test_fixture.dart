import 'dart:io';

import 'package:tir_sportif/interfaces/backup_location_provider.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/repositories/weapon_repository.dart';
import 'package:tir_sportif/services/backup_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/weapon_service.dart';

import 'fake_session_repository.dart';

class FakeBackupLocationProvider implements BackupLocationProvider {
  FakeBackupLocationProvider({
    required this.temporaryDirectory,
    this.selectedDirectory,
  });

  Directory temporaryDirectory;
  String? selectedDirectory;
  Object? selectionError;

  @override
  Future<Directory> getTemporaryDirectory() async => temporaryDirectory;

  @override
  Future<String?> selectExportDirectory() async {
    final error = selectionError;
    if (error != null) throw error;
    return selectedDirectory;
  }
}

class BackupServiceTestFixture {
  BackupServiceTestFixture._({
    required this.service,
    required this.locationProvider,
  });

  final BackupService service;
  final FakeBackupLocationProvider locationProvider;

  static Future<BackupServiceTestFixture> create(
    Directory temporaryDirectory, {
    String? selectedDirectory,
  }) async {
    final sessionRepository = FakeSessionRepository();
    final sessionService = SessionService(repository: sessionRepository);
    await sessionService.addSession(
      DetailedShootingSession(
        weapon: 'Pistolet de test',
        caliber: '9 mm',
        date: DateTime(2026, 9, 4),
        status: 'réalisée',
        category: 'entraînement',
        synthese: 'Export déterministe',
        series: [
          Series(
            distance: 25,
            points: 45,
            shotCount: 5,
            groupSize: 8,
          ),
        ],
      ),
    );

    final goalRepository = _MemoryGoalRepository([
      Goal(
        id: 'goal-export',
        title: 'Objectif exporté',
        metric: GoalMetric.sessionCount,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 4,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 2),
        priority: 0,
      ),
    ]);
    final weaponRepository = _MemoryWeaponRepository([
      Weapon(
        id: 'weapon-export',
        name: 'Pistolet de test',
        createdAt: DateTime(2026, 9, 1),
      ),
    ]);
    final locationProvider = FakeBackupLocationProvider(
      temporaryDirectory: temporaryDirectory,
      selectedDirectory: selectedDirectory,
    );
    final service = BackupService(
      sessionService: sessionService,
      goalService: GoalService(
        sessionRepository: sessionRepository,
        goalRepository: goalRepository,
      ),
      weaponService: WeaponService(
        weaponRepository: weaponRepository,
        sessionRepository: sessionRepository,
      ),
      locationProvider: locationProvider,
    );
    return BackupServiceTestFixture._(
      service: service,
      locationProvider: locationProvider,
    );
  }
}

class _MemoryGoalRepository implements GoalRepository {
  _MemoryGoalRepository(this.goals);

  final List<Goal> goals;

  @override
  Future<void> delete(String id) async =>
      goals.removeWhere((goal) => goal.id == id);

  @override
  Future<void> deleteAll() async => goals.clear();

  @override
  Future<List<Goal>> getAll() async => List<Goal>.from(goals);

  @override
  Future<void> put(Goal goal) async {
    goals.removeWhere((item) => item.id == goal.id);
    goals.add(goal);
  }
}

class _MemoryWeaponRepository implements WeaponRepository {
  _MemoryWeaponRepository(this.weapons);

  final List<Weapon> weapons;

  @override
  Future<void> clear() async => weapons.clear();

  @override
  Future<void> delete(String id) async =>
      weapons.removeWhere((weapon) => weapon.id == id);

  @override
  Future<List<Weapon>> getAll() async => List<Weapon>.from(weapons);

  @override
  Future<void> put(Weapon weapon) async {
    weapons.removeWhere((item) => item.id == weapon.id);
    weapons.add(weapon);
  }
}
