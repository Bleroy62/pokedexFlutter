Pokédex Flutter
Une application Pokédex développée avec Flutter qui permet de parcourir et de rechercher des Pokémon avec leurs informations détaillées en français.

📱 Fonctionnalités
Navigation complète : Parcourez les 1025 Pokémon avec les boutons précédent/suivant

Recherche intelligente : Recherchez par nom français ou numéro de Pokémon

Interface en français : Tous les noms, types et descriptions en français

Design authentique : Interface inspirée du Pokédex classique avec thème rouge

Informations détaillées :

Image officielle du Pokémon

Types avec codes couleurs

Taille et poids

Description du Pokémon

🛠️ Technologies utilisées
Flutter - Framework de développement

Dart - Langage de programmation

PokéAPI - API pour les données Pokémon

HTTP - Pour les requêtes réseau

📦 Installation
Prérequis
Flutter SDK (version 3.0 ou supérieure)

Dart SDK

Un émulateur ou appareil physique

🎯 Utilisation
Navigation basique : Utilisez les flèches gauche/droite pour naviguer entre les Pokémon

Recherche : Tapez dans la barre de recherche pour trouver un Pokémon spécifique

Affichage des détails : Chaque Pokémon affiche :

Son numéro et nom français

Son image officielle

Ses types avec codes couleurs

Sa taille et son poids

Sa description

🔧 Configuration
L'application utilise l'API PokéAPI officielle :

Base URL: https://pokeapi.co/api/v2/

Limit: 1025 Pokémon (de la 1ère à la 8ème génération)

📝 Notes techniques
Gestion des langues : L'application priorise les noms et descriptions en français, avec fallback en anglais si nécessaire

Performance : Mise en cache des données de recherche pour une expérience fluide

UI/UX : Interface responsive adaptée aux mobiles

🐛 Problèmes connus
Les Pokémon après le #899 peuvent avoir des descriptions en anglais car l'API PokéAPI n'a pas encore toutes les traductions françaises

Certains sprites peuvent ne pas être disponibles pour tous les Pokémon
