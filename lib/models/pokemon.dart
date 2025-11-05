class Pokemon {
  final int id;
  final String name;
  final String frenchName;
  final List<String> types;
  final List<String> frenchTypes;
  final String imageUrl;
  final int height;
  final int weight;
  final String description;
  final List<Pokemon> evolutionLine;

  Pokemon({
    required this.id,
    required this.name,
    required this.frenchName,
    required this.types,
    required this.frenchTypes,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.description,
    required this.evolutionLine,
  });

  factory Pokemon.fromJson(
    Map<String, dynamic> json, {
    String? frenchName,
    List<String>? frenchTypes,
    String? description,
    List<Pokemon>? evolutionLine,
  }) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      frenchName: frenchName ?? json['name'],
      types: (json['types'] as List)
          .map((type) => type['type']['name'] as String)
          .toList(),
      frenchTypes: frenchTypes ?? 
          (json['types'] as List)
              .map((type) => type['type']['name'] as String)
              .toList(),
      imageUrl: json['sprites']['other']['official-artwork']['front_default'] ??
          json['sprites']['front_default'],
      height: json['height'],
      weight: json['weight'],
      description: description ?? '',
      evolutionLine: evolutionLine ?? [],
    );
  }

  String get formattedName {
    final nameToUse = frenchName;
    return nameToUse[0].toUpperCase() + nameToUse.substring(1);
  }

  String get formattedId => '#${id.toString().padLeft(3, '0')}';
}