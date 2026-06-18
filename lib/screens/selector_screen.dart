import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/hero_repository.dart';
import '../models/game_hero.dart';
import '../models/hero_role.dart';
import '../models/player_pick.dart';
import 'hero_editor_screen.dart';
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

    final heroesByRole = <HeroRole, List<GameHero>>{};
    for (final role in HeroRole.values) {
      final heroes = await _repository.getHeroesByRole(role);
      if (heroes.length < 4) {
        throw StateError('Для роли "${role.title}" нужно минимум 4 персонажа.');
      }
      heroesByRole[role] = heroes;
    }

    final roles = [
      HeroRole.tank,
      HeroRole.tank,
      HeroRole.damage,
      HeroRole.damage,
      HeroRole.healer,
      HeroRole.healer,
    ]..shuffle(_random);

    final nextPicks = <PlayerPick>[];

    for (var playerIndex = 0; playerIndex < 6; playerIndex++) {
      final role = roles[playerIndex];
      final pool = List<GameHero>.of(heroesByRole[role]!)..shuffle(_random);
      final options = pool.take(2).toList();
      final label = 'Игрок ${playerIndex + 1}: ${role.title}';

      await _spinWheel(label);
      nextPicks.add(
        PlayerPick(
          playerNumber: playerIndex + 1,
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
      floatingActionButton: FloatingActionButton.extended(
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
