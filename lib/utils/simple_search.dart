import 'package:http/http.dart' as http;
import 'dart:convert';

class SimpleSearch {
  static List<Map<String, dynamic>> _allPokemon = [];
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print("Initialisation de la recherche...");
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=1025'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        // Charger tous les Pokémon avec leurs IDs
        _allPokemon = await Future.wait(results.map((pokemon) async {
          final url = pokemon['url'] as String;
          final segments = url.split('/');
          final id = int.parse(segments[segments.length - 2]);
          
          // Récupérer le nom français
          final frenchName = await _getFrenchName(id);
          
          return {
            'id': id,
            'name': pokemon['name'],
            'frenchName': frenchName,
            'url': url,
          };
        }));
        
        _isInitialized = true;
        print("Recherche initialisée avec ${_allPokemon.length} Pokémon");
      } else {
        print("Erreur HTTP: ${response.statusCode}");
      }
    } catch (e) {
      print('Error initializing search: $e');
    }
  }

  static Future<String> _getFrenchName(int id) async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$id'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final names = data['names'] as List;
        
        // Chercher le nom français
        for (var name in names) {
          if (name['language']['name'] == 'fr') {
            return name['name'];
          }
        }
      }
    } catch (e) {
      print('Error getting French name for Pokémon $id: $e');
    }
    
    // Fallback au nom anglais si pas de nom français trouvé
    return _allPokemon.firstWhere((p) => p['id'] == id, orElse: () => {'name': '?'})['name'];
  }

  static List<Map<String, dynamic>> search(String query) {
    if (query.isEmpty) return [];
    
    final searchTerm = query.toLowerCase();
    final results = _allPokemon.where((pokemon) {
      final String frenchName = (pokemon['frenchName'] ?? '').toLowerCase();
      final String id = pokemon['id'].toString();
      
      // Recherche uniquement sur le nom français et l'ID
      return frenchName.contains(searchTerm) || 
             id.contains(searchTerm);
    }).take(1025).toList();
    
    print("Recherche '$query': ${results.length} résultats");
    return results;
  }
}