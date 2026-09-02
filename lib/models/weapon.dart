/// Une arme du râtelier personnel (NT-008) : un simple nom, sans marque,
/// modèle, calibre ni autre métadonnée. Persistée en Map dans la box Hive
/// `weapons` (pas d'adapter généré, à l'instar d'[Exercise]).
class Weapon {
  final String id;
  final String name;
  final DateTime createdAt;

  Weapon({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Weapon copyWith({String? name}) => Weapon(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  static Weapon fromMap(Map<String, dynamic> map) => Weapon(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
