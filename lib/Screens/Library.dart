import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120E2B), // Fond sombre cohérent
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 20),
                _buildCategoryChips(),
                const SizedBox(height: 20),
                // Expanded permet à la liste de prendre tout l'espace restant
                Expanded(
                  child: _buildSongList(),
                ),
              ],
            ),
            
            // Barre de navigation flottante (onglet central actif)
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=150&q=80'),
          ),
          Row(
            children: [
              _buildIconButton(Icons.search),
              const SizedBox(width: 10),
              _buildIconButton(Icons.notifications_none),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 22),
        onPressed: () {},
      ),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Your library',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Liked Songs', 'Playlists', 'Downloads'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          int index = entry.key;
          String label = entry.value;
          bool isSelected = index == 0; // "All" est sélectionné par défaut
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFA838FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white30,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSongList() {
    // Données factices basées sur votre maquette
    final List<Map<String, String>> songs = [
      {'title': 'Save Your Tears', 'artist': 'The Weeknd', 'duration': '3:35', 'color': '0xFF5C258D'},
      {'title': 'Happier Than Ever', 'artist': 'Billie Eilish', 'duration': '4:57', 'color': '0xFF4389A2'},
      {'title': 'Sunflower', 'artist': 'Post Malone', 'duration': '2:40', 'color': '0xFFF37335'},
      {'title': 'Believer', 'artist': 'Imagine Dragons', 'duration': '3:25', 'color': '0xFF8A2387'},
      {'title': 'Positions', 'artist': 'Ariana Grande', 'duration': '3:02', 'color': '0xFF11998E'},
      {'title': 'Shivers', 'artist': 'Ed Sheeran', 'duration': '3:28', 'color': '0xFFE55D87'},
      {'title': 'Ghost', 'artist': 'Justin Bieber', 'duration': '3:12', 'color': '0xFF0F2027'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120), // Padding bas pour la nav bar
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Pochette de l'album (Remplacée par un conteneur coloré pour l'exemple)
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(song['color']!)),
                      Color(int.parse(song['color']!)).withOpacity(0.5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.music_note, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Titre et Artiste
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song['artist']!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Durée
              Text(
                song['duration']!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              
              // Bouton Play
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        width: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF2A273A).withOpacity(0.9), // Effet de verre
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.home_outlined, color: Colors.white54, size: 28),
            
            // Onglet central actif (Musique)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFA838FF), // Accent violet
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 24),
            ),
            
            const Icon(Icons.settings_outlined, color: Colors.white54, size: 28),
          ],
        ),
      ),
    );
  }
}
