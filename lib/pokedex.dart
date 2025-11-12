import 'package:flutter/material.dart';
import 'dart:async';
import 'models/pokemon.dart';
import 'services/pokemon_service.dart';
import 'utils/simple_search.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  int currentPokemonIndex = 1;
  final totalPokemon = 1025;
  Pokemon? currentPokemon;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];
  final _searchDebounce = Duration(milliseconds: 200);
  Timer? _debounceTimer;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    testTypeImages();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialiser la recherche mais ne pas attendre
    SimpleSearch.initialize().catchError((e) {
      print("Erreur initialisation recherche: $e");
    });

    // Charger le premier Pokémon immédiatement
    _loadPokemon(currentPokemonIndex);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon(int id) async {
    if (id < 1 || id > totalPokemon) return;

    setState(() {
      isLoading = true;
    });

    try {
      final pokemon = await PokemonService.getPokemon(id);
      if (mounted) {
        setState(() {
          currentPokemon = pokemon;
          isLoading = false;
          _showSearchResults = false;
          currentPokemonIndex = id; // Mettre à jour l'index
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error loading Pokémon $id: $e');

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement Pokémon #$id'),
          backgroundColor: Colors.red,
        ),
      );
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_searchFocus.hasFocus) {
          _searchFocus.requestFocus();
        }
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
    _loadPokemon(nextIndex);
  }

  void previousPokemon() {
    final prevIndex =
        currentPokemonIndex > 1 ? currentPokemonIndex - 1 : totalPokemon;
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

String _getTypeImageUrl(String type) {
  final typeMapping = {
    'normal': 'normal',
    'feu': 'fire',
    'eau': 'water',
    'électrik': 'electric',
    'plante': 'grass',
    'glace': 'ice',
    'combat': 'fighting',
    'poison': 'poison',
    'sol': 'ground',
    'vol': 'flying',
    'psy': 'psychic',
    'insecte': 'bug',
    'roche': 'rock',
    'spectre': 'ghost',
    'dragon': 'dragon',
    'ténèbres': 'dark',
    'acier': 'steel',
    'fée': 'fairy',
  };

  final englishType = typeMapping[type.toLowerCase()] ?? 'normal';
  
  return 'https://raw.githubusercontent.com/msikma/pokesprite/master/misc/type-logos/gen8/$englishType.png';
}

  void testTypeImages() {
    final testTypes = ['plante', 'feu', 'eau', 'poison'];

    for (final type in testTypes) {
      final url = _getTypeImageUrl(type);
      print('🔍 Testing type: $type');
      print('📸 URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[800],
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'POKEDEX',
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 0, 0, 255),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _searchPokemon,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        elevation: 0,
      ),

      body: Stack(
        children: [
          Column(
            children: [
              // pokedex screen
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(16),
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
                          : SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // id and name
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // pokemon image
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Stack(
                                    children: [
                                      if (currentPokemon != null)
                                        Image.network(
                                          currentPokemon!.imageUrl,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
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
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            // Fallback vers l'image standard si l'artwork officiel échoue
                                            return Image.network(
                                              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${currentPokemon!.id}.png',
                                              fit: BoxFit.contain,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                // Dernier fallback
                                                return Image.network(
                                                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${currentPokemon!.id}.png',
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.error,
                                                            color: Colors.red,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'Image non disponible',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12),
                                // Types avec images - Version debug
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children:
                                      currentPokemon!.frenchTypes.map((type) {
                                        return _buildTypeBadge(
                                          type,
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 10),

                                // height and weight
                                SizedBox(
                                  height: 50,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
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
                                const SizedBox(height: 10),

                                // evolution line
                                if (currentPokemon!.evolutionLine.isNotEmpty &&
                                    currentPokemon!.evolutionLine.any(
                                      (evo) => evo.id != currentPokemon!.id,
                                    )) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Évolutions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      height: 80,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children:
                                            currentPokemon!.evolutionLine.map((
                                              evolution,
                                            ) {
                                              final bool isCurrent =
                                                  evolution.id ==
                                                  currentPokemon!.id;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    currentPokemonIndex =
                                                        evolution.id;
                                                  });
                                                  _loadPokemon(evolution.id);
                                                },
                                                child: Container(
                                                  width: 100,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isCurrent
                                                            ? Colors.red[100]
                                                            : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color:
                                                          isCurrent
                                                              ? Colors.red[800]!
                                                              : Colors.grey[300]!,
                                                      width: isCurrent ? 1 : 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      // Image du Pokémon
                                                      Container(
                                                        width: 50,
                                                        height: 44,
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue[50],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                25,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                Colors.grey[300]!,
                                                          ),
                                                        ),
                                                        child: Image.network(
                                                          evolution.imageUrl,
                                                          fit: BoxFit.contain,
                                                          loadingBuilder: (
                                                            context,
                                                            child,
                                                            loadingProgress,
                                                          ) {
                                                            if (loadingProgress ==
                                                                null) {
                                                              return child;
                                                            }
                                                            return Center(
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
                                                            );
                                                          },
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Center(
                                                              child: Text(
                                                                evolution
                                                                    .formattedId
                                                                    .replaceAll(
                                                                      '#',
                                                                      '',
                                                                    ),
                                                                style: TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      Colors
                                                                          .red[800],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        evolution.formattedName,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              isCurrent
                                                                  ? Colors
                                                                      .red[800]
                                                                  : Colors
                                                                      .black87,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Aucune évolution',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // Description
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    minHeight: 60,
                                    maxHeight: 80,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      currentPokemon!.description,
                                      style: const TextStyle(
                                        fontSize: 12,
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

              // nav control - previus pokemon and next pokemon
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: previousPokemon,
                        child: Container(
                          height: 45,
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
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: nextPokemon,
                        child: Container(
                          height: 45,
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
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // search result (superposés par-dessus le contenu)
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showSearchResults = false;
                    _searchController.clear();
                    _searchFocus.unfocus();
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: 5,
              left: 16,
              right: 16,
              child: Container(
                height: 600,
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
                        dense: true,
                        leading: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Image.network(
                            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  '#${id.toString().padLeft(3, '0')}',
                                  style: TextStyle(
                                    fontSize: 7,
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
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '#${id.toString().padLeft(3, '0')}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        onTap: () => _selectPokemonFromSearch(pokemon),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Méthode pour construire les éléments de statistiques
  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              fontSize: 8,
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

  // Dans la partie Wrap des types, remplacez le Container entier par :
  Widget _buildTypeBadge(String type) {
    final imageUrl = _getTypeImageUrl(type);
    print('🎯 Building badge for: $type');
    print('🔗 Using URL: $imageUrl');

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: _getTypeColor(type),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image du type avec CachedNetworkImage
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(2),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              color: Colors.white,
              errorWidget: (context, url, error) {
                print('❌ CachedNetworkImage error for $type: $error');
                print('🔗 Failed URL: $url');
                return _buildTypeFallback(type);
              },
              progressIndicatorBuilder: (context, url, downloadProgress) {
                return Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      value: downloadProgress.progress,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          // Nom du type
          Text(
            type[0].toUpperCase() + type.substring(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeImage(String imageUrl, String type) {
    // Si c'est un SVG, utiliser un widget différent
    if (imageUrl.endsWith('.svg')) {
      return _buildSvgTypeImage(imageUrl, type);
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erreur image type $type: $error');
          return _buildTypeFallback(type);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildSvgTypeImage(String imageUrl, String type) {
    // Pour SVG, on peut utiliser un placeholder simple
    // ou utiliser le package flutter_svg si vous l'installez
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          type[0].toUpperCase(),
          style: TextStyle(
            color: _getTypeColor(type),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFallback(String type) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          type[0].toUpperCase(),
          style: TextStyle(
            color: _getTypeColor(type),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
