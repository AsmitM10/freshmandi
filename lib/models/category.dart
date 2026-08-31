class Category {
  final String id;
  final String name;
  final String emoji;
  final bool active;

  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.active = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: (json['emoji'] as String?) ?? '🧺',
        active: (json['status'] as String? ?? 'active') == 'active',
      );

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'emoji': emoji,
        'status': active ? 'active' : 'inactive',
      };
}
