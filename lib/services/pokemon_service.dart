import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokemonService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  static Future<Pokemon> getPokemon(int id) async {
  try {
    // Récupérer les données de base du Pokémon
    final pokemonResponse = await http.get(Uri.parse('$_baseUrl/pokemon/$id'));
    
    if (pokemonResponse.statusCode == 200) {
      final pokemonData = json.decode(pokemonResponse.body);
      
      // Récupérer les données de l'espèce pour le nom français, la description ET les évolutions
      final speciesResponse = await http.get(Uri.parse('$_baseUrl/pokemon-species/$id'));
      Map<String, dynamic> speciesData = {};
      String frenchName = pokemonData['name'];
      String description = '';

      if (speciesResponse.statusCode == 200) {
        speciesData = json.decode(speciesResponse.body);
        frenchName = _getFrenchName(speciesData);
        description = _getFrenchDescription(speciesData);
      }
      
      // Récupérer les types en français
      final frenchTypes = await _getFrenchTypes(pokemonData['types']);
      
      // Récupérer la ligne d'évolution
      final evolutionLine = await _getEvolutionLine(speciesData);
      
      return Pokemon.fromJson(
        pokemonData, 
        frenchName: frenchName, 
        frenchTypes: frenchTypes,
        description: description,
        evolutionLine: evolutionLine,
      );
    } else {
      throw Exception('Failed to load Pokémon');
    }
  } catch (e) {
    print('Error loading Pokémon $id: $e');
    throw Exception('Failed to load Pokémon');
  }
}

static String _getFrenchName(Map<String, dynamic> speciesData) {
  try {
    final names = speciesData['names'] as List?;
    if (names != null) {
      for (var name in names) {
        if (name['language']['name'] == 'fr') {
          return name['name'];
        }
      }
    }
  } catch (e) {
    print('Error getting French name: $e');
  }

  // Fallback: use the species 'name' field if present, otherwise a generic label
  return speciesData['name'] ?? 'Pokémon';
}
  static String _getFrenchDescription(Map<String, dynamic> speciesData) {
    try {
      final flavorTextEntries = speciesData['flavor_text_entries'] as List;

      for (var entry in flavorTextEntries) {
        if (entry['language']['name'] == 'fr') {
          String description = entry['flavor_text']
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          return description;
        }
      }

      for (var entry in flavorTextEntries) {
        if (entry['language']['name'] == 'en') {
          String description = entry['flavor_text']
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          return description;
        }
      }
    } catch (e) {
      print('Error getting description: $e');
    }

    return 'Aucune description disponible.';
  }

  static Future<List<String>> _getFrenchTypes(List<dynamic> types) async {
    final frenchTypes = <String>[];

    for (final type in types) {
      final typeUrl = type['type']['url'];
      try {
        final response = await http.get(Uri.parse(typeUrl));

        if (response.statusCode == 200) {
          final typeData = json.decode(response.body);
          final names = typeData['names'] as List;
          String frenchName = typeData['name'];

          for (var name in names) {
            if (name['language']['name'] == 'fr') {
              frenchName = name['name'];
              break;
            }
          }
          frenchTypes.add(frenchName);
        }
      } catch (e) {
        frenchTypes.add(type['type']['name']);
      }
    }

    return frenchTypes;
  }

  // Dans PokemonService, ajoutez cette méthode
static Future<String> getTypeImageUrl(String typeName) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/type/$typeName'));
    if (response.statusCode == 200) {
      final typeData = json.decode(response.body);
      // L'API ne fournit pas directement l'image du type dans les données de base
      // On utilise donc une URL construite
      return 'https://pokeapi.co/media/sprites/types/generation-viii/sword-shield/$typeName.png';
    }
  } catch (e) {
    print('Error fetching type image for $typeName: $e');
  }
  
  // Fallback
  return 'https://pokeapi.co/media/sprites/types/generation-viii/sword-shield/normal.png';
}

  /// Récupère toute la ligne d'évolution du Pokémon
static Future<List<Pokemon>> _getEvolutionLine(Map<String, dynamic> speciesData) async {
  try {
    final evolutionChainUrl = speciesData['evolution_chain']?['url'];
    if (evolutionChainUrl == null) return [];

    final evolutionResponse = await http.get(Uri.parse(evolutionChainUrl));
    if (evolutionResponse.statusCode != 200) return [];

    final evolutionData = json.decode(evolutionResponse.body);
    final evolutionIds = _getAllEvolutionIds(evolutionData['chain']);
    
    print('Evolution IDs: $evolutionIds');
    
    final evolutionPokemons = <Pokemon>[];
    
    for (var evolutionId in evolutionIds) {
      try {
        // Utiliser la méthode sans récursion
        final pokemon = await _getPokemonWithoutEvolution(evolutionId);
        evolutionPokemons.add(pokemon);
      } catch (e) {
        print('Error loading evolution ID $evolutionId: $e');
      }
    }
    
    return evolutionPokemons;
  } catch (e) {
    print('Error getting evolution line: $e');
    return [];
  }
}
  /// Parcourt récursivement la chaîne d'évolution pour obtenir tous les IDs
  static List<int> _getAllEvolutionIds(Map<String, dynamic> chain) {
    final ids = <int>[];

    void traverseChain(Map<String, dynamic> currentChain) {
      final speciesUrl = currentChain['species']['url'] as String;
      // Extraire l'ID de l'URL (ex: "https://pokeapi.co/api/v2/pokemon-species/681/" -> 681)
      final id = int.parse(
        speciesUrl.split('/').where((s) => s.isNotEmpty).last,
      );
      ids.add(id);

      final evolvesTo = currentChain['evolves_to'] as List;
      if (evolvesTo.isNotEmpty) {
        for (var evolution in evolvesTo) {
          traverseChain(evolution);
        }
      }
    }

    traverseChain(chain);
    return ids;
  }

  /// Charge un Pokémon sans récupérer sa ligne d'évolution (pour éviter la récursion)
  static Future<Pokemon> _getPokemonWithoutEvolution(int id) async {
    try {
      // Récupérer les données de base du Pokémon
      final pokemonResponse = await http.get(
        Uri.parse('$_baseUrl/pokemon/$id'),
      );

      if (pokemonResponse.statusCode == 200) {
        final pokemonData = json.decode(pokemonResponse.body);

        // Récupérer les données de l'espèce pour le nom français, la description
        final speciesResponse = await http.get(
          Uri.parse('$_baseUrl/pokemon-species/$id'),
        );
        Map<String, dynamic> speciesData = {};
        String frenchName = pokemonData['name'];
        String description = '';

        if (speciesResponse.statusCode == 200) {
          speciesData = json.decode(speciesResponse.body);
          frenchName = _getFrenchName(speciesData);
          description = _getFrenchDescription(speciesData);
        }

        // Récupérer les types en français
        final frenchTypes = await _getFrenchTypes(pokemonData['types']);

        // NE PAS appeler _getEvolutionLine ici pour éviter la récursion
        return Pokemon.fromJson(
          pokemonData,
          frenchName: frenchName,
          frenchTypes: frenchTypes,
          description: description,
          evolutionLine: [], // Ligne d'évolution vide
        );
      } else {
        throw Exception('Failed to load Pokémon');
      }
    } catch (e) {
      print('Error loading Pokémon $id: $e');
      throw Exception('Failed to load Pokémon');
    }
  }
}
