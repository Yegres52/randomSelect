import 'package:flutter/material.dart';

import '../models/player_pick.dart';
import '../theme/role_colors.dart';

class PicksPanel extends StatelessWidget {
  const PicksPanel({super.key, required this.picks});

  final List<PlayerPick> picks;

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return Center(
        child: Text(
          'Здесь появятся 6 игроков и по 2 персонажа на выбор.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: picks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pick = picks[index];
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: roleColor(pick.role).withValues(alpha: 0.55),
            ),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xff1b1f2a),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor(pick.role),
                  foregroundColor: Colors.white,
                  child: Text('${pick.playerNumber}'),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pick.playerName} - ${pick.role.title}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final hero in pick.options)
                            Chip(
                              label: Text(hero.name),
                              side: BorderSide.none,
                              backgroundColor: const Color(0xff2a3040),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
