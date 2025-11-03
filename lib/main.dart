import 'package:flutter/material.dart';
import 'pokedex.dart'; // Import du fichier pokedex

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
        // Retirez fontFamily ou utilisez une police par défaut
      ),
      home: const PokedexScreen(),
    );
  }
}