import 'package:flutter/material.dart';
import 'dart:async';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';
import 'utils/simple_search.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  int currentPokemonIndex = 1;
  final totalPokemon = 1025;
  Pokemon? currentPokemon;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];
  final _searchDebounce = Duration(milliseconds: 200);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await SimpleSearch.initialize();
    _loadPokemon(currentPokemonIndex);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPokemon(int id) async {
    setState(() {
      isLoading = true;
    });

    try {
      final pokemon = await PokemonService.getPokemon(id);
      setState(() {
        currentPokemon = pokemon;
        isLoading = false;
        _showSearchResults = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading Pokémon: $e');
    }
  }

  void _searchPokemon(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }

    _debounceTimer = Timer(_searchDebounce, () {
      final results = SimpleSearch.search(query);
      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
      });
    });
  }

  void _selectPokemonFromSearch(Map<String, dynamic> pokemonData) {
    final int id = pokemonData['id'];
    setState(() {
      currentPokemonIndex = id;
      _searchController.clear();
      _showSearchResults = false;
    });
    _loadPokemon(id);
  }

  void nextPokemon() {
    final nextIndex = (currentPokemonIndex % totalPokemon) + 1;
    setState(() {
      currentPokemonIndex = nextIndex;
    });
    _loadPokemon(nextIndex);
  }

  void previousPokemon() {
    final prevIndex =
        currentPokemonIndex > 1 ? currentPokemonIndex - 1 : totalPokemon;
    setState(() {
      currentPokemonIndex = prevIndex;
    });
    _loadPokemon(prevIndex);
  }

  Color _getTypeColor(String type) {
    final colors = {
      'normal': Colors.grey[400]!,
      'feu': Colors.orange[600]!,
      'eau': Colors.blue[400]!,
      'électrik': Colors.yellow[600]!,
      'plante': Colors.green[500]!,
      'glace': Colors.cyan[300]!,
      'combat': Colors.red[600]!,
      'poison': Colors.purple[400]!,
      'sol': Colors.orange[300]!,
      'vol': Colors.indigo[200]!,
      'psy': Colors.pink[400]!,
      'insecte': Colors.lightGreen[500]!,
      'roche': Colors.brown[400]!,
      'spectre': Colors.deepPurple[400]!,
      'dragon': Colors.indigo[600]!,
      'ténèbres': Colors.brown[900]!,
      'acier': Colors.blueGrey[400]!,
      'fée': Colors.pink[200]!,
    };
    return colors[type.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[800],
      appBar: AppBar(
        title: const Text(
          'Pokédex',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          // ÉCRAN DU POKÉDEX - CORRIGÉ POUR ÉVITER LE DÉBORDEMENT
          Expanded(
            flex: 3, // Augmenté pour donner plus d'espace
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 4),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : currentPokemon == null
                      ? const Center(child: Text('Pokémon non trouvé'))
                      : SingleChildScrollView( // Ajouté pour permettre le défilement
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Numéro et Nom
                              Text(
                                currentPokemon!.formattedId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentPokemon!.formattedName,
                                style: const TextStyle(
                                  fontSize: 22, // Légèrement réduit
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Image du Pokémon - Taille réduite
                              Container(
                                height: 350, // Réduit de 200 à 150
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey),
                                ),
                                padding: const EdgeInsets.all(12), // Réduit
                                child: Image.network(
                                  currentPokemon!.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error, size: 30), // Réduit
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Types
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: currentPokemon!.frenchTypes
                                    .map(
                                      (type) => Chip(
                                        label: Text(
                                          type[0].toUpperCase() +
                                              type.substring(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11, // Réduit
                                          ),
                                        ),
                                        backgroundColor: _getTypeColor(type),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),

                              // Taille et Poids - Hauteur réduite
                              SizedBox(
                                height: 60, // Conteneur de hauteur fixe
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatItem(
                                      'Taille',
                                      '${currentPokemon!.height / 10} m',
                                    ),
                                    _buildStatItem(
                                      'Poids',
                                      '${currentPokemon!.weight / 10} kg',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Description - Hauteur adaptative
                              Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: 60, // Hauteur minimale
                                  maxHeight: 100, // Hauteur maximale pour éviter débordement
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    currentPokemon!.description,
                                    style: const TextStyle(
                                      fontSize: 13, // Légèrement réduit
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),

          // BARRE DE RECHERCHE - ESPACE RÉDUIT
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 45, // Réduit
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un Pokémon...',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.red[700], size: 20),
                        onPressed: () => _searchPokemon(_searchController.text),
                      ),
                    ),
                    onChanged: _searchPokemon,
                  ),
                ),

                // Résultats de recherche - Hauteur réduite
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    height: 120, // Réduit
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                        ),
                      ],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final pokemon = _searchResults[index];
                        final int id = pokemon['id'];
                        final String frenchName =
                            pokemon['frenchName'] ?? pokemon['name'];

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true, // Rend le ListTile plus compact
                            leading: Container(
                              width: 35, // Réduit
                              height: 35, // Réduit
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                                width: 30,
                                height: 30,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      '#${id.toString().padLeft(3, '0')}',
                                      style: TextStyle(
                                        fontSize: 7, // Réduit
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[800],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            title: Text(
                              frenchName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13, // Réduit
                              ),
                            ),
                            subtitle: Text(
                              '#${id.toString().padLeft(3, '0')}',
                              style: TextStyle(
                                fontSize: 9, // Réduit
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 12, // Réduit
                              color: Colors.grey[600],
                            ),
                            onTap: () => _selectPokemonFromSearch(pokemon),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // CONTROLES DE NAVIGATION - HAUTEUR RÉDUITE
          Container(
            height: 60, // Réduit
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: previousPokemon,
                    child: Container(
                      height: 45, // Réduit
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue[800]!.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22, // Réduit
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: nextPokemon,
                    child: Container(
                      height: 45, // Réduit
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue[800]!.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 22, // Réduit
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour construire les éléments de statistiques
  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}