import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/game_hero.dart';
import '../models/hero_role.dart';
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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE heroes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            role TEXT NOT NULL
          )
        ''');
        await _seed(db);
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

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    for (final entry in heroSeedData.entries) {
      for (final name in entry.value) {
        batch.insert('heroes', {'name': name, 'role': entry.key.name});
      }
    }

    await batch.commit(noResult: true);
  }
}
