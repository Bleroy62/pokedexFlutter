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
          // Écran du Pokédex
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 4),
              ),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : currentPokemon == null
                      ? const Center(child: Text('Pokémon non trouvé'))
                      : Column(
                        children: [
                          // Partie supérieure avec l'image
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                border: Border.all(color: Colors.grey),
                              ),
                              margin: const EdgeInsets.all(12),
                              child: Image.network(
                                currentPokemon!.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, size: 50),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Dans la partie inférieure avec les infos, remplacez par :
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    currentPokemon!.formattedId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    currentPokemon!.formattedName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children:
                                        currentPokemon!.frenchTypes
                                            .map(
                                              (type) => Chip(
                                                label: Text(
                                                  type[0].toUpperCase() +
                                                      type.substring(1),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: _getTypeColor(
                                                  type,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  // Stats additionnelles
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        'Taille: ${currentPokemon!.height / 10} m',
                                      ),
                                      Text(
                                        'Poids: ${currentPokemon!.weight / 10} kg',
                                      ),
                                    ],
                                  ),
                                  // NOUVEAU : Description
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currentPokemon!.description,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),

          // BARRE DE RECHERCHE - AVEC IMAGES ET NOMS FRANÇAIS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Champ de recherche
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un Pokémon...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.red[700]),
                        onPressed: () => _searchPokemon(_searchController.text),
                      ),
                    ),
                    onChanged: _searchPokemon,
                  ),
                ),

                // Résultats de recherche - AVEC IMAGES ET NOMS FRANÇAIS
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
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
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback aux sprites réguliers si les artworks officiels ne sont pas disponibles
                                  return Image.network(
                                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          '#${id.toString().padLeft(3, '0')}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[800],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  frenchName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '#${id.toString().padLeft(3, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
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

          // Contrôles de navigation
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: previousPokemon,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: nextPokemon,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
