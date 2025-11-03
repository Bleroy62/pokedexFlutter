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
        
        // Récupérer les données de l'espèce pour le nom français ET la description
        final speciesResponse = await http.get(Uri.parse('$_baseUrl/pokemon-species/$id'));
        Map<String, dynamic> speciesData = {};
        String frenchName = pokemonData['name']; // Nom anglais par défaut
        String description = ''; // Description par défaut

        if (speciesResponse.statusCode == 200) {
          speciesData = json.decode(speciesResponse.body);
          frenchName = _getFrenchName(speciesData);
          description = _getFrenchDescription(speciesData); // NOUVEAU
        }
        
        // Récupérer les types en français
        final frenchTypes = await _getFrenchTypes(pokemonData['types']);
        
        return Pokemon.fromJson(
          pokemonData, 
          frenchName: frenchName, 
          frenchTypes: frenchTypes,
          description: description, // NOUVEAU
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
      final names = speciesData['names'] as List;
      for (var name in names) {
        if (name['language']['name'] == 'fr') {
          return name['name'];
        }
      }
      return speciesData['name'];
    } catch (e) {
      return speciesData['name'];
    }
  }

  // NOUVELLE MÉTHODE : Récupérer la description en français
  static String _getFrenchDescription(Map<String, dynamic> speciesData) {
    try {
      final flavorTextEntries = speciesData['flavor_text_entries'] as List;
      
      // Chercher une description en français
      for (var entry in flavorTextEntries) {
        if (entry['language']['name'] == 'fr') {
          // Nettoyer la description : retirer les sauts de ligne et espaces superflus
          String description = entry['flavor_text']
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
          return description;
        }
      }
      
      // Si pas de description en français, chercher en anglais
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
}