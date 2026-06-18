class AppPlayer {
  const AppPlayer({
    required this.id,
    required this.position,
    required this.name,
  });

  final int id;
  final int position;
  final String name;

  factory AppPlayer.fromMap(Map<String, Object?> map) {
    return AppPlayer(
      id: map['id'] as int,
      position: map['position'] as int,
      name: map['name'] as String,
    );
  }
}
