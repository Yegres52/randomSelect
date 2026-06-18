import 'hero_role.dart';

class RoleCounts {
  const RoleCounts({
    required this.tanks,
    required this.damage,
    required this.healers,
  });

  final int tanks;
  final int damage;
  final int healers;

  int get total => tanks + damage + healers;

  int countFor(HeroRole role) {
    return switch (role) {
      HeroRole.tank => tanks,
      HeroRole.damage => damage,
      HeroRole.healer => healers,
    };
  }

  RoleCounts copyWithRole(HeroRole role, int value) {
    return switch (role) {
      HeroRole.tank => RoleCounts(
          tanks: value,
          damage: damage,
          healers: healers,
        ),
      HeroRole.damage => RoleCounts(
          tanks: tanks,
          damage: value,
          healers: healers,
        ),
      HeroRole.healer => RoleCounts(
          tanks: tanks,
          damage: damage,
          healers: value,
        ),
    };
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'tanks': tanks,
      'damage': damage,
      'healers': healers,
    };
  }

  factory RoleCounts.fromMap(Map<String, Object?> map) {
    return RoleCounts(
      tanks: map['tanks'] as int,
      damage: map['damage'] as int,
      healers: map['healers'] as int,
    );
  }
}
