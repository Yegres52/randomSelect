import 'hero_role.dart';

class GameHero {
  const GameHero({
    required this.id,
    required this.name,
    required this.role,
  });

  final int id;
  final String name;
  final HeroRole role;

  factory GameHero.fromMap(Map<String, Object?> map) {
    return GameHero(
      id: map['id'] as int,
      name: map['name'] as String,
      role: HeroRole.values.byName(map['role'] as String),
    );
  }
}
