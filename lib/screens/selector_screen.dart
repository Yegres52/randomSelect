import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/hero_repository.dart';
import '../models/game_hero.dart';
import '../models/hero_role.dart';
import '../models/player_pick.dart';
import 'hero_editor_screen.dart';
import 'player_settings_screen.dart';
import '../widgets/picks_panel.dart';
import '../widgets/wheel_panel.dart';

class SelectorScreen extends StatefulWidget {
  const SelectorScreen({super.key});

  @override
  State<SelectorScreen> createState() => _SelectorScreenState();
}

class _SelectorScreenState extends State<SelectorScreen>
    with SingleTickerProviderStateMixin {
  final _repository = HeroRepository();
  final _random = Random();
  final _picks = <PlayerPick>[];

  late final AnimationController _wheelController;
  late Animation<double> _wheelTurns;

  var _isLoading = false;
  var _currentWheelLabel = 'Нажми старт';

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _wheelTurns = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  Future<void> generatePicks() async {
    setState(() {
      _isLoading = true;
      _picks.clear();
      _currentWheelLabel = 'Крутим...';
    });

    try {
      await _generatePicks();
    } on StateError catch (error) {
      _showPickError(error.message);
    } catch (_) {
      _showPickError('Не удалось выбрать персонажей.');
    }
  }

  Future<void> _generatePicks() async {
    final heroesByRole = <HeroRole, List<GameHero>>{};
    for (final role in HeroRole.values) {
      final heroes = await _repository.getHeroesByRole(role);
      if (heroes.length < 2) {
        throw StateError('Для роли "${role.title}" нужно минимум 2 персонажа.');
      }
      heroesByRole[role] = heroes;
    }

    final players = await _repository.getPlayers();
    final roleCounts = await _repository.getRoleCounts();
    if (roleCounts.total == 0) {
      throw StateError('Выбери хотя бы одну роль.');
    }

    final selectedPlayers = players.take(roleCounts.total).toList();
    final roles = <HeroRole>[
      for (var i = 0; i < roleCounts.tanks; i++) HeroRole.tank,
      for (var i = 0; i < roleCounts.damage; i++) HeroRole.damage,
      for (var i = 0; i < roleCounts.healers; i++) HeroRole.healer,
    ]..shuffle(_random);

    final nextPicks = <PlayerPick>[];

    for (var playerIndex = 0;
        playerIndex < selectedPlayers.length;
        playerIndex++) {
      final player = selectedPlayers[playerIndex];
      final role = roles[playerIndex];
      final pool = List<GameHero>.of(heroesByRole[role]!)..shuffle(_random);
      final options = pool.take(2).toList();
      final label = '${player.name}: ${role.title}';

      await _spinWheel(label);
      nextPicks.add(
        PlayerPick(
          playerNumber: player.position,
          playerName: player.name,
          role: role,
          options: options,
        ),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _picks
          ..clear()
          ..addAll(nextPicks);
        _currentWheelLabel = '${options[0].name} / ${options[1].name}';
      });

      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _currentWheelLabel = 'Готово';
    });
  }

  void _showPickError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _currentWheelLabel = 'Нажми старт';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _spinWheel(String label) async {
    if (!mounted) {
      return;
    }

    final start = _wheelTurns.value;
    final end = start + 4 + _random.nextDouble() * 2;
    setState(() {
      _currentWheelLabel = label;
      _wheelTurns = Tween<double>(begin: start, end: end).animate(
        CurvedAnimation(parent: _wheelController, curve: Curves.easeOutCubic),
      );
    });
    _wheelController.reset();
    await _wheelController.forward().orCancel.catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'players',
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PlayerSettingsScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.group_outlined),
            label: const Text('Игроки'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'heroes',
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HeroEditorScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Список'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: WheelPanel(
                      animation: _wheelTurns,
                      label: _currentWheelLabel,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : generatePicks,
                    ),
                  ),
                  const SizedBox(width: 20, height: 20),
                  Expanded(
                    flex: isWide ? 6 : 1,
                    child: PicksPanel(picks: _picks),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
