
# Titune - Application mobile de musique

Titune, Application mobile de lecture musicale développée avec le framework Flutter. Ce projet se concentre sur la création d'une interface utilisateur immersive et l'implémentation de la logique de contrôle audio.

## Fonctionnalités Principales

* **Interface Utilisateur :** Architecture comprenant une page d'accueil dynamique, une section bibliothèque et un lecteur interactif (Now Playing).
* **Contrôle Audio :** Gestion des flux de lecture, incluant les fonctions Play, Pause, Suivant et Précédent.
* **Gestion des Métadonnées :** Affichage des informations relatives aux pistes (titres, artistes, visuels).
* **Navigation Optimisée :** Transitions fluides entre les différents modules de l'application.

## Spécifications Techniques

* **Framework :** Flutter (Dart)
* **plateforme :** Support pour Android uniquement pour le moment.
* **Composants :** Utilisation de widgets personnalisés pour les listes 
* **Architecture :** Organisation modulaire du code pour séparer la logique métier de l'interface via des services dédiés.

## Structure du Répertoire

L'organisation du dossier `lib` suit une architecture rigoureuse :

* `lib/Models/` : Définition des modèles de données structurant les objets musicaux.
* `lib/Screens/` : Contient les écrans principaux de l'application.
* `lib/Widgets/` : Éléments d'interface utilisateur (UI) réutilisables.
* `lib/Services/` : Logique métier, gestion de listes.
* `lib/Utils/` : Fonctions utilitaires, constantes et thèmes globaux.

## Installation et Lancement

1. **Clonage du dépôt :**
   ```bash
   git clone [https://github.com/fenix237/music_app.git](https://github.com/fenix237/music_app.git)

 * Installation des dépendances :
   flutter pub get

 * Exécution de l'application :
   flutter run

Informations sur l'Auteur
Dongmo Giresse – Développeur Fullstack Flutter
 * GitHub : fenix237
 * Localisation : Yaoundé, Cameroun
