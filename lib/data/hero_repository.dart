import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_player.dart';
import '../models/game_hero.dart';
import '../models/hero_role.dart';
import '../models/role_counts.dart';
import 'hero_seed_data.dart';

class HeroRepository {
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final path = p.join(await getDatabasesPath(), 'random_select.db');
    final database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createHeroesTable(db);
        await _createPlayersTable(db);
        await _createRoleCountsTable(db);
        await _seedHeroes(db);
        await _seedPlayers(db);
        await _seedRoleCounts(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPlayersTable(db);
          await _createRoleCountsTable(db);
          await _seedPlayers(db);
          await _seedRoleCounts(db);
        }
      },
    );

    _database = database;
    return database;
  }

  Future<List<GameHero>> getHeroesByRole(HeroRole role) async {
    final db = await database;
    final rows = await db.query(
      'heroes',
      where: 'role = ?',
      whereArgs: [role.name],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(GameHero.fromMap).toList();
  }

  Future<Map<HeroRole, List<GameHero>>> getHeroesGroupedByRole() async {
    final result = <HeroRole, List<GameHero>>{};
    for (final role in HeroRole.values) {
      result[role] = await getHeroesByRole(role);
    }
    return result;
  }

  Future<void> addHero({
    required String name,
    required HeroRole role,
  }) async {
    final db = await database;
    await db.insert('heroes', {'name': name.trim(), 'role': role.name});
  }

  Future<void> updateHero(GameHero hero) async {
    final db = await database;
    await db.update(
      'heroes',
      {'name': hero.name.trim(), 'role': hero.role.name},
      where: 'id = ?',
      whereArgs: [hero.id],
    );
  }

  Future<void> deleteHero(int id) async {
    final db = await database;
    await db.delete(
      'heroes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AppPlayer>> getPlayers() async {
    final db = await database;
    final rows = await db.query(
      'players',
      orderBy: 'position ASC',
    );
    return rows.map(AppPlayer.fromMap).toList();
  }

  Future<void> updatePlayerName({
    required int id,
    required String name,
  }) async {
    final db = await database;
    await db.update(
      'players',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RoleCounts> getRoleCounts() async {
    final db = await database;
    final rows = await db.query(
      'role_counts',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      const counts = RoleCounts(tanks: 2, damage: 2, healers: 2);
      await updateRoleCounts(counts);
      return counts;
    }

    return RoleCounts.fromMap(rows.first);
  }

  Future<void> updateRoleCounts(RoleCounts counts) async {
    final db = await database;
    await db.insert(
      'role_counts',
      counts.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _createHeroesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS heroes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPlayersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createRoleCountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS role_counts (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        tanks INTEGER NOT NULL,
        damage INTEGER NOT NULL,
        healers INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedHeroes(Database db) async {
    final batch = db.batch();

    for (final entry in heroSeedData.entries) {
      for (final name in entry.value) {
        batch.insert('heroes', {'name': name, 'role': entry.key.name});
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> _seedPlayers(Database db) async {
    final batch = db.batch();
    for (var i = 1; i <= 6; i++) {
      batch.insert(
        'players',
        {'position': i, 'name': 'Игрок $i'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedRoleCounts(Database db) async {
    await db.insert(
      'role_counts',
      const RoleCounts(tanks: 2, damage: 2, healers: 2).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
