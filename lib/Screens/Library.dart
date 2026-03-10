import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'PlayerScreen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Instance de OnAudioQuery
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Vérification et demande des permissions
  Future<void> _checkPermissions() async {
    // Demande la permission audio (Android 13+) et stockage (Android 12 et -)
    var storageStatus = await Permission.storage.request();
    var audioStatus = await Permission.audio.request();

    if (storageStatus.isGranted || audioStatus.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      // Optionnel : Gérer le refus avec un dialogue ou l'ouverture des paramètres
      setState(() {
        _hasPermission = false;
      });
    }
  }

  // Convertisseur de millisecondes en format "Minutes:Secondes"
  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return "0:00";
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120E2B),
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
                // Affichage de la vraie liste des musiques
                Expanded(
                  child: _buildRealSongList(),
                ),
              ],
            ),
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
            backgroundImage: AssetImage('assets/images/profile.jpeg'),
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
          bool isSelected = index == 0;

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

  // Remplacement par la vraie liste on_audio_query
  Widget _buildRealSongList() {
    if (!_hasPermission) {
      return Center(
        child: Text(
          "Permission requise pour lire les fichiers audio.",
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      );
    }

    return FutureBuilder<List<SongModel>>(
      // ignoreCase, orderType, etc. pourront être modifiés pour le tri plus tard
      future: _audioQuery.querySongs(
        ignoreCase: true,
        orderType: OrderType.ASC_OR_SMALLER,
        sortType: null,
        uriType: UriType.EXTERNAL,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFA838FF)));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucune musique trouvée", style: TextStyle(color: Colors.white)));
        }

        // On a nos musiques !
        List<SongModel> songs = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            
            return InkWell(
              onTap: () {
                // TODO: Passer l'URI de la chanson au PlayerScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Affiche la pochette de l'album (ou un dégradé par défaut si absente)
                    QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkFit: BoxFit.cover,
                      nullArtworkWidget: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFA838FF).withOpacity(0.8),
                              const Color(0xFF2A273A)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.music_note, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Titre et Artiste
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist ?? "Artiste inconnu",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Durée calculée à partir des millisecondes
                    Text(
                      _formatDuration(song.duration),
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
              ),
            );
          },
        );
      },
    );
  }

  
}