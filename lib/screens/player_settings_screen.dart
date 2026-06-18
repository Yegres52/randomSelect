import 'package:flutter/material.dart';

import '../data/hero_repository.dart';
import '../models/app_player.dart';
import '../models/hero_role.dart';
import '../models/role_counts.dart';
import '../theme/role_colors.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  final _repository = HeroRepository();

  late Future<_PlayerSettingsData> _dataFuture;
  RoleCounts? _counts;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_PlayerSettingsData> _loadData() async {
    final players = await _repository.getPlayers();
    final counts = await _repository.getRoleCounts();
    _counts = counts;
    return _PlayerSettingsData(players: players, counts: counts);
  }

  void _reload() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _setRoleCount(HeroRole role, int value) async {
    final current = _counts;
    if (current == null || value < 0) {
      return;
    }

    final next = current.copyWithRole(role, value);
    if (next.total > 6) {
      return;
    }

    setState(() {
      _counts = next;
    });
    await _repository.updateRoleCounts(next);
  }

  Future<void> _renamePlayer(AppPlayer player) async {
    final controller = TextEditingController(text: player.name);

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Игрок ${player.position}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Имя игрока'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(context).pop(trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.of(context).pop(trimmed);
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null) {
      return;
    }

    await _repository.updatePlayerName(id: player.id, name: name);
    if (!mounted) {
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Игроки')),
      body: FutureBuilder<_PlayerSettingsData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }

          final counts = _counts ?? data.counts;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RoleCountsPanel(
                counts: counts,
                onChanged: _setRoleCount,
              ),
              const SizedBox(height: 18),
              Text(
                'Имена игроков',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final player in data.players)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xff1b1f2a),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${player.position}')),
                      title: Text(player.name),
                      trailing: IconButton(
                        tooltip: 'Изменить имя',
                        onPressed: () => _renamePlayer(player),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleCountsPanel extends StatelessWidget {
  const _RoleCountsPanel({
    required this.counts,
    required this.onChanged,
  });

  final RoleCounts counts;
  final void Function(HeroRole role, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xff1b1f2a),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Роли в выборке',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${counts.total}/6'),
              ],
            ),
            const SizedBox(height: 12),
            for (final role in HeroRole.values)
              _RoleCounterRow(
                role: role,
                value: counts.countFor(role),
                total: counts.total,
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleCounterRow extends StatelessWidget {
  const _RoleCounterRow({
    required this.role,
    required this.value,
    required this.total,
    required this.onChanged,
  });

  final HeroRole role;
  final int value;
  final int total;
  final void Function(HeroRole role, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: roleColor(role),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(role.title)),
          IconButton(
            tooltip: 'Уменьшить',
            onPressed: value > 0 ? () => onChanged(role, value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Увеличить',
            onPressed: total < 6 ? () => onChanged(role, value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _PlayerSettingsData {
  const _PlayerSettingsData({
    required this.players,
    required this.counts,
  });

  final List<AppPlayer> players;
  final RoleCounts counts;
}
