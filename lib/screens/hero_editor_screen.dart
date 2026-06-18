import 'package:flutter/material.dart';

import '../data/hero_repository.dart';
import '../models/game_hero.dart';
import '../models/hero_role.dart';
import '../theme/role_colors.dart';

class HeroEditorScreen extends StatefulWidget {
  const HeroEditorScreen({super.key});

  @override
  State<HeroEditorScreen> createState() => _HeroEditorScreenState();
}

class _HeroEditorScreenState extends State<HeroEditorScreen> {
  final _repository = HeroRepository();

  late Future<Map<HeroRole, List<GameHero>>> _heroesFuture;

  @override
  void initState() {
    super.initState();
    _heroesFuture = _repository.getHeroesGroupedByRole();
  }

  void _reload() {
    setState(() {
      _heroesFuture = _repository.getHeroesGroupedByRole();
    });
  }

  Future<void> _showHeroDialog({
    required HeroRole initialRole,
    GameHero? hero,
  }) async {
    var selectedRole = hero?.role ?? initialRole;
    final controller = TextEditingController(text: hero?.name ?? '');

    final result = await showDialog<_HeroFormResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(hero == null ? 'Добавить персонажа' : 'Изменить'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Имя персонажа',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(
                        _HeroFormResult(name: name, role: selectedRole),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<HeroRole>(
                    segments: [
                      for (final role in HeroRole.values)
                        ButtonSegment(
                          value: role,
                          label: Text(role.title),
                        ),
                    ],
                    selected: {selectedRole},
                    onSelectionChanged: (selection) {
                      setDialogState(() {
                        selectedRole = selection.first;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      _HeroFormResult(name: name, role: selectedRole),
                    );
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == null) {
      return;
    }

    if (hero == null) {
      await _repository.addHero(name: result.name, role: result.role);
    } else {
      await _repository.updateHero(
        GameHero(id: hero.id, name: result.name, role: result.role),
      );
    }

    if (!mounted) {
      return;
    }
    _reload();
  }

  Future<void> _deleteHero(GameHero hero) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить персонажа?'),
          content: Text(hero.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _repository.deleteHero(hero.id);

    if (!mounted) {
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: HeroRole.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Список персонажей'),
          bottom: TabBar(
            tabs: [
              for (final role in HeroRole.values) Tab(text: role.title),
            ],
          ),
        ),
        body: FutureBuilder<Map<HeroRole, List<GameHero>>>(
          future: _heroesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final heroesByRole = snapshot.data ?? {};

            return TabBarView(
              children: [
                for (final role in HeroRole.values)
                  _HeroRoleList(
                    role: role,
                    heroes: heroesByRole[role] ?? const [],
                    onAdd: () => _showHeroDialog(initialRole: role),
                    onEdit: (hero) => _showHeroDialog(
                      initialRole: role,
                      hero: hero,
                    ),
                    onDelete: _deleteHero,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroRoleList extends StatelessWidget {
  const _HeroRoleList({
    required this.role,
    required this.heroes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final HeroRole role;
  final List<GameHero> heroes;
  final VoidCallback onAdd;
  final ValueChanged<GameHero> onEdit;
  final ValueChanged<GameHero> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: roleColor(role),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${role.title}: ${heroes.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: heroes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final hero = heroes[index];
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xff1b1f2a),
                ),
                child: ListTile(
                  title: Text(hero.name),
                  subtitle: Text(hero.role.title),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Изменить',
                        onPressed: () => onEdit(hero),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Удалить',
                        onPressed: () => onDelete(hero),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeroFormResult {
  const _HeroFormResult({
    required this.name,
    required this.role,
  });

  final String name;
  final HeroRole role;
}
