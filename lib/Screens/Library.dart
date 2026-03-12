import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'PlayerScreen.dart';
import '../Utils/Globals.dart'; // ← IMPORT DES VARIABLES GLOBALES

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late Future<List<SongModel>> _songsFuture;

  bool _hasPermission = false;

  // --- VARIABLES ÉTAT LECTURE (comme PlayerScreen) ---
  int? _playingSongId;
  SongModel? _currentSong;
  List<SongModel> _currentPlaylist = [];
  int _currentIndex = -1;
  StreamSubscription? _playerStateSubscription;
  // -------------------------------------------------

  bool _isPlaying = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();

    _songsFuture = _audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    // LISTENER COMME DANS PLAYERSCREEN ✅
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        
        // LOGIQUE FIN DE CHANSON (exactement comme PlayerScreen)
        if (state.processingState == ProcessingState.completed) {
          _handleSongEnd();
        }
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // === LOGIQUE DE LECTURE (copiée de PlayerScreen) ===
  
  void _handleSongEnd() {
    if (repeatMode == 2) {
      // Répéter un titre
      _loadSong(_currentIndex);
    } else {
      // Passage au suivant (avec shuffle)
      _skipNext();
    }
  }

  Future<void> _loadSong(int index) async {
    if (index < 0 || index >= _currentPlaylist.length || _currentPlaylist.isEmpty) return;

    setState(() {
      _currentIndex = index;
    });

    try {
      final song = _currentPlaylist[_currentIndex];
      _currentSong = song;
      _playingSongId = song.id;

      final source = AudioSource.uri(
        Uri.parse(song.uri!),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? "Album inconnu",
          title: song.title,
          artist: song.artist ?? "Artiste inconnu",
          artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
        ),
      );

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Erreur changement morceau : $e");
    }
  }

  void _skipNext() {
    if (isShuffle) {
      if (_currentPlaylist.length <= 1) return;
      
      int nextIndex;
      do {
        nextIndex = Random().nextInt(_currentPlaylist.length);
      } while (nextIndex == _currentIndex);
      
      _loadSong(nextIndex);
    } else {
      if (_currentIndex < _currentPlaylist.length - 1) {
        _loadSong(_currentIndex + 1);
      } else if (repeatMode == 1) {
        _loadSong(0);
      }
    }
  }

  void _skipPrevious() {
    if (isShuffle) {
      _skipNext();
    } else {
      if (_currentIndex > 0) {
        _loadSong(_currentIndex - 1);
      } else if (repeatMode == 1) {
        _loadSong(_currentPlaylist.length - 1);
      }
    }
  }

  Future<void> _checkPermissions() async {
    var storageStatus = await Permission.storage.request();
    var audioStatus = await Permission.audio.request();

    if (storageStatus.isGranted || audioStatus.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _togglePlay(SongModel song, bool changeScreen) async {
    if (song.uri == null) return;

    if (_playingSongId == song.id) {
      if (changeScreen) return;
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } else {
      // Nouvelle chanson : met à jour la playlist et l'index
      final songsIndex = _currentPlaylist.indexOf(song);
      if (songsIndex != -1) {
        _currentIndex = songsIndex;
      } else {
        _currentPlaylist = [song];
        _currentIndex = 0;
      }
      
      await _loadSong(_currentIndex);
    }
  }

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
                Expanded(child: _buildRealSongList()),
              ],
            ),
            _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    if (_currentSong == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                songs: _currentPlaylist,
                currentIndex: _currentIndex,
                player: _audioPlayer,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A273A),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(children: [
            QueryArtworkWidget(
              id: _currentSong!.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              artworkWidth: 46,
              artworkHeight: 46,
              artworkBorder: BorderRadius.circular(23),
              nullArtworkWidget: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: const Color(0xFFA838FF).withOpacity(0.8),
                ),
                child: const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSong!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _currentSong!.artist ?? "Artiste inconnu",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey<bool>(_isPlaying),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              onPressed: () => _togglePlay(_currentSong!, false),
            ),
            const SizedBox(width: 4),
          ]),
        ),
      ),
    );
  }

  // Widgets inchangés (header, title, chips...)
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
          Row(children: [
            _buildIconButton(_isSearching ? Icons.close : Icons.search, onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchText = "";
                }
              });
            }),
            const SizedBox(width: 10),
            _buildIconButton(Icons.notifications_none, onTap: () {}),
          ])
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {required VoidCallback onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
      child: IconButton(icon: Icon(icon, color: Colors.white70, size: 22), onPressed: onTap),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                hintText: "Rechercher un titre, un artiste...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            )
          : const Text('Your library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
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
              border: Border.all(color: isSelected ? Colors.transparent : Colors.white30),
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

  Widget _buildRealSongList() {
    if (!_hasPermission) {
      return Center(
        child: Text("Permission requise pour lire les fichiers audio.", style: TextStyle(color: Colors.white.withOpacity(0.6))),
      );
    }

    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
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

        List<SongModel> songs = snapshot.data!.where((song) {
          final title = song.title.toLowerCase();
          final artist = (song.artist ?? "").toLowerCase();
          return title.contains(_searchText) || artist.contains(_searchText);
        }).toList();

        if (songs.isEmpty) {
          return const Center(child: Text("Aucun résultat pour cette recherche", style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            bool isCurrentSong = _playingSongId == song.id;

            return InkWell(
              onTap: () async {
                setState(() {
                  _currentPlaylist = List.from(songs); // Copie pour éviter les mutations
                  _currentIndex = index;
                });
                await _togglePlay(song, true);
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
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
                          colors: [const Color(0xFFA838FF).withOpacity(0.8), const Color(0xFF2A273A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: isCurrentSong ? const Color(0xFFA838FF) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          child: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist ?? "Artiste inconnu",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(_formatDuration(song.duration), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPlaylist = List.from(songs);
                        _currentIndex = index;
                      });
                      _togglePlay(song, false);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentSong && _isPlaying ? const Color(0xFFA838FF).withOpacity(0.2) : Colors.white.withOpacity(0.1),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isCurrentSong && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey<bool>(isCurrentSong && _isPlaying),
                          color: isCurrentSong && _isPlaying ? const Color(0xFFA838FF) : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
