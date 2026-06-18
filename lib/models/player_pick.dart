import 'game_hero.dart';
import 'hero_role.dart';

class PlayerPick {
  const PlayerPick({
    required this.playerNumber,
    required this.role,
    required this.options,
  });

  final int playerNumber;
  final HeroRole role;
  final List<GameHero> options;
}
