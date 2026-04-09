import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Services/LikedSongs.dart';
import '../Services/PLayListManager.dart';
import '../Services/RecentSongs.dart';
import 'PlayerScreen.dart';
import 'package:app_links/app_links.dart';
import '../Utils/Globals.dart'; // ← IMPORT DES VARIABLES GLOBALES

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<SongModel>> _songsFuture;

  bool _hasPermission = false;

  int? _playingSongId;
  bool _isProcessingSnippet = false;
  // -------------------------------------------------

  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  StreamSubscription<String>? _notificationActionSubscription;
  List<String> _currentPathSegments = [];
  int _selectedCategoryIndex = 0;
  String? _selectedAlbumName;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _appLinks = AppLinks();
    _initDeepLinks();

    _songsFuture = audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
        });

        if (state.processingState == ProcessingState.completed &&
            !_isProcessingSnippet) {
          _isProcessingSnippet = true;
          _handleSongEnd();

          Future.delayed(const Duration(milliseconds: 500), () {
            _isProcessingSnippet = false;
          });
        }
      }
    });

    audioPlayer.sequenceStateStream.listen((sequenceState) {
      if (sequenceState == null || !mounted) return;

      final currentItem = sequenceState.currentSource?.tag as MediaItem?;

      if (currentItem != null) {
        setState(() {
          _playingSongId = int.parse(currentItem.id);

          if (currentPlaylist.isNotEmpty) {
            try {
              currentSong = currentPlaylist.firstWhere(
                (song) => song.id.toString() == currentItem.id,
              );
              currentIndex = currentPlaylist.indexOf(currentSong!);
            } catch (e) {
              debugPrint("Le morceau n'est pas dans la playlist actuelle");
            }
          }
        });
      }
    });

    likedSongsList();
    _loadPlaylistNames();
  }

  Future<void> _loadPlaylistNames() async {
    final playlistManager = PlaylistManager();
    playlistNames = await playlistManager.getNonEmptyPlaylists();
    if (mounted) setState(() {});
  }

  likedSongsList() async {
    List<String> ids = await loadLikedSongs();
    print("La taille des ids: ${ids.length}");
    setState(() {
      likedSongIds = ids;
    });
  }

  void _initDeepLinks() async {
    // 1. Cas où l'application est ouverte via un fichier alors qu'elle était FERMÉE
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleExternalFile(initialUri);
      }
    } catch (e) {
      debugPrint("Erreur lien initial: $e");
    }

    // 2. Cas où l'application est déjà en arrière-plan (BACKGROUND/FOREGROUND)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleExternalFile(uri);
    }, onError: (err) {
      debugPrint("Erreur stream liens: $err");
    });
  }

  Future<void> _handleExternalFile(Uri uri) async {
    // On récupère la liste actuelle pour voir si le son existe déjà
    List<SongModel> allSongs = await audioQuery.querySongs(
      ignoreCase: true,
      uriType: UriType.EXTERNAL,
    );

    SongModel? matchingSong;
    try {
      matchingSong = allSongs.firstWhere((s) => s.uri == uri.toString());
    } catch (e) {
      debugPrint("Aucun morceau ne correspond à l'URI: $uri");
    }

    if (matchingSong != null) {
      _togglePlay(matchingSong, false);
    } else {
      _playDirectFile(uri);
    }
  }

  Future<void> _playDirectFile(Uri uri) async {
    // Extraction du nom du fichier pour l'affichage
    String fileName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "Fichier externe";

    final source = AudioSource.uri(
      uri,
      tag: MediaItem(
        id: uri.toString(),
        album: "Explorateur de fichiers",
        title: fileName,
        artist: "Inconnu",
        // On peut mettre une icône par défaut ici
      ),
    );

    await audioPlayer.setAudioSource(source);
    await audioPlayer.play();

    if (mounted) {
      setState(() {
        _playingSongId = null; // Pas d'ID on_audio_query
        isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    playerStateSubscription?.cancel();
    _searchController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  String removeAccents(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str.toLowerCase();
  }

  // === LOGIQUE DE LECTURE (copiée de PlayerScreen) ===

  void _handleSongEnd() {
    if (repeatMode == 2) {
      // Répéter un titre
      _loadSong(currentIndex);
    } else {
      // Passage au suivant (avec shuffle)
      _skipNext();
    }
  }

  Future<void> _loadSong(int index) async {
    if (index < 0 || index >= currentPlaylist.length || currentPlaylist.isEmpty)
      return;

    setState(() {
      currentIndex = index;
    });

    try {
      final song = currentPlaylist[currentIndex];
      await addToRecent(song.id.toString());
      currentSong = song;
      _playingSongId = song.id;

      final source = AudioSource.uri(
        Uri.parse(song.uri!),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? "Album inconnu",
          title: song.title,
          artist: song.artist ?? "Artiste inconnu",
          artUri: Uri.parse(
              'content://media/external/audio/media/${song.id}/albumart'),
        ),
      );

      await audioPlayer.setAudioSource(source);
      await audioPlayer.play();
    } catch (e) {
      debugPrint("Erreur changement morceau : $e");
    }
  }

  void _skipNext() {
    if (isShuffle) {
      if (currentPlaylist.length <= 1) return;

      int nextIndex;
      do {
        nextIndex = Random().nextInt(currentPlaylist.length);
      } while (nextIndex == currentIndex);

      _loadSong(nextIndex);
    } else {
      if (currentIndex < currentPlaylist.length - 1) {
        _loadSong(currentIndex + 1);
      } else if (repeatMode == 1) {
        _loadSong(0);
      }
    }
  }

  void _skipPrevious() {
    if (isShuffle) {
      _skipNext();
    } else {
      if (currentIndex > 0) {
        _loadSong(currentIndex - 1);
      } else if (repeatMode == 1) {
        _loadSong(currentPlaylist.length - 1);
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
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } else {
      // Nouvelle chanson : met à jour la playlist et l'index
      final songsIndex = currentPlaylist.indexOf(song);
      if (songsIndex != -1) {
        currentIndex = songsIndex;
      } else {
        currentPlaylist = [song];
        currentIndex = 0;
      }

      await _loadSong(currentIndex);
    }
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return "0:00";
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Map<String, List<SongModel>> _groupByFolder(List<SongModel> songs) {
    Map<String, List<SongModel>> folderMap = {};

    for (var song in songs) {
      String path = song.data;
      List<String> parts = path.split('/');

      String folderName = parts.length > 1 ? parts[parts.length - 2] : "Racine";

      if (!folderMap.containsKey(folderName)) {
        folderMap[folderName] = [];
      }
      folderMap[folderName]!.add(song);
    }
    return folderMap;
  }

  Map<String, dynamic> _getItemsAtCurrentPath(List<SongModel> allSongs) {
    Set<String> subFolders = {};
    List<SongModel> songsInFolder = [];

    for (var song in allSongs) {
      // Nettoyage et découpage du chemin (on enlève le "/" initial si présent)
      List<String> segments = song.data.startsWith('/')
          ? song.data.substring(1).split('/')
          : song.data.split('/');

      // Si on est à la racine, on cherche le premier segment commun (souvent 'storage')
      // Sinon, on vérifie si le début du chemin correspond à notre position actuelle
      bool isInside = true;
      for (int i = 0; i < _currentPathSegments.length; i++) {
        if (i >= segments.length || segments[i] != _currentPathSegments[i]) {
          isInside = false;
          break;
        }
      }

      if (isInside) {
        int nextIndex = _currentPathSegments.length;
        // S'il reste plus d'un segment après le chemin actuel, c'est un sous-dossier
        if (nextIndex < segments.length - 1) {
          subFolders.add(segments[nextIndex]);
        }
        // S'il ne reste que le nom du fichier, c'est une chanson dans ce dossier
        else if (nextIndex == segments.length - 1) {
          songsInFolder.add(song);
        }
      }
    }

    return {
      'folders': subFolders.toList()..sort(),
      'songs': songsInFolder,
    };
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
    if (currentSong == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                songs: currentPlaylist,
                currentIndex: currentIndex,
                player: audioPlayer,
              ),
            ),
          ).then((value) => setState(() {}));
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
              id: currentSong!.id,
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
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    currentSong!.artist ?? "Artiste inconnu",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey<bool>(isPlaying),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              onPressed: () => _togglePlay(currentSong!, false),
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
            _buildIconButton(isVisibleSearch ? Icons.close : Icons.search,
                onTap: () {
              setState(() {
                isVisibleSearch = !isVisibleSearch;
                if (!isVisibleSearch) {
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
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
      child: IconButton(
          icon: Icon(icon, color: Colors.white70, size: 22), onPressed: onTap),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: isVisibleSearch
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
                  _searchText = value.toLowerCase().trim();
                });
              },
            )
          : const Text('Your library',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Folders', 'Liked Songs', 'Albums', 'Playlists'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          int index = entry.key;
          String label = entry.value;
          bool isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFA838FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white30),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
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
        child: Text("Permission requise pour lire les fichiers audio.",
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
      );
    }

    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA838FF)));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text("Erreur: ${snapshot.error}",
                  style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("Aucune musique trouvée",
                  style: TextStyle(color: Colors.white)));
        }

        List<SongModel> allSongs = snapshot.data!;

        // --- SCÉNARIO A : RECHERCHE ACTIVE (GLOBALE SUR TOUT) ---
        if (_searchText.isNotEmpty) {
          final query = removeAccents(_searchText);
          final queryWords =
              query.split(' ').where((word) => word.isNotEmpty).toList();

          List<SongModel> searchSongs = allSongs.where((song) {
            final songTitle = removeAccents(song.title);
            final songArtist = removeAccents(song.artist ?? "");

            final combinedInfo = "$songTitle $songArtist";

            return queryWords.every((word) => combinedInfo.contains(word));
          }).toList();

          Map<String, List<SongModel>> albumMap = {};
          for (var song in allSongs) {
            String album = song.album ?? "Inconnu";
            if (!albumMap.containsKey(album)) albumMap[album] = [];
            albumMap[album]!.add(song);
          }

          List<String> matchingAlbums = albumMap.keys.where((albumName) {
            final cleanedAlbumName = removeAccents(albumName);
            return queryWords.every((word) => cleanedAlbumName.contains(word));
          }).toList();

          if (searchSongs.isEmpty && matchingAlbums.isEmpty) {
            return const Center(
              child: Text(
                "Aucun morceau ou album trouvé",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            children: [
              if (searchSongs.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "Titres",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...searchSongs
                    .asMap()
                    .entries
                    .map((entry) =>
                        _buildSongItem(entry.value, searchSongs, entry.key))
                    .toList(),
              ],

              // --- SECTION ALBUMS ---
              if (matchingAlbums.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "Albums",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: matchingAlbums.length,
                  itemBuilder: (context, index) {
                    String name = matchingAlbums[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAlbumName = name;
                          _selectedCategoryIndex =
                              3; // Bascule sur l'onglet Album
                          isVisibleSearch = false; // Ferme la recherche
                          _searchText = "";
                          _searchController.clear();
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: QueryArtworkWidget(
                              id: albumMap[name]!.first.id,
                              type: ArtworkType.AUDIO,
                              artworkFit: BoxFit.cover,
                              artworkWidth: double.infinity,
                              artworkHeight: double.infinity,
                              artworkBorder: BorderRadius.circular(15),
                              nullArtworkWidget: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Center(
                                  child: Icon(Icons.album,
                                      color: Color(0xFFA838FF), size: 40),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        }

        // --- SCÉNARIO B : NAVIGATION PAR DOSSIERS (Catégorie Index 1) ---
        if (_selectedCategoryIndex == 1) {
          Set<String> subFolders = {};
          List<SongModel> songsAtCurrentLevel = [];

          for (var song in allSongs) {
            List<String> allSegments = song.data.startsWith('/')
                ? song.data.substring(1).split('/')
                : song.data.split('/');

            int rootIndex = allSegments.indexOf('0');
            List<String> segments =
                (rootIndex != -1 && rootIndex < allSegments.length - 1)
                    ? allSegments.sublist(rootIndex + 1)
                    : allSegments;

            bool isMatch = true;
            for (int i = 0; i < _currentPathSegments.length; i++) {
              if (i >= segments.length ||
                  segments[i] != _currentPathSegments[i]) {
                isMatch = false;
                break;
              }
            }

            if (isMatch) {
              int nextIdx = _currentPathSegments.length;
              if (nextIdx < segments.length - 1) {
                subFolders.add(segments[nextIdx]);
              } else if (nextIdx == segments.length - 1) {
                songsAtCurrentLevel.add(song);
              }
            }
          }

          final folderList = subFolders.toList()..sort();
          final showBackButton = _currentPathSegments.isNotEmpty;

          return ListView.builder(
            key: PageStorageKey("folder_${_currentPathSegments.join('/')}"),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            itemCount: (showBackButton ? 1 : 0) +
                folderList.length +
                songsAtCurrentLevel.length,
            itemBuilder: (context, index) {
              if (showBackButton && index == 0) {
                return ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.white30),
                  title: const Text("..",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  onTap: () =>
                      setState(() => _currentPathSegments.removeLast()),
                );
              }

              int adjustedIndex = showBackButton ? index - 1 : index;

              if (adjustedIndex < folderList.length) {
                String folderName = folderList[adjustedIndex];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder, color: Color(0xFFA838FF)),
                  ),
                  title: Text(folderName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () =>
                      setState(() => _currentPathSegments.add(folderName)),
                );
              }

              int songIdx = adjustedIndex - folderList.length;
              return _buildSongItem(
                  songsAtCurrentLevel[songIdx], songsAtCurrentLevel, songIdx);
            },
          );
        }

        // --- SCÉNARIO C : LIKED SONGS (Catégorie Index 2) ---
        if (_selectedCategoryIndex == 2) {
          print("La taille de allsongs:  ${allSongs.length}");
          print("La taille de likedSongIds:  ${likedSongIds.length}");

          List<SongModel> likedSongs = allSongs
              .where((s) => likedSongIds.contains(s.id.toString()))
              .toList();

          if (likedSongs.isEmpty) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, color: Colors.white24, size: 60),
                SizedBox(height: 10),
                Text("Aucun coup de cœur",
                    style: TextStyle(color: Colors.white54)),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            itemCount: likedSongs.length,
            itemBuilder: (context, index) =>
                _buildSongItem(likedSongs[index], likedSongs, index),
          );
        }

        if (_selectedCategoryIndex == 3) {
          if (_selectedAlbumName == null) {
            // AFFICHER LA LISTE DES ALBUMS
            Map<String, List<SongModel>> albumMap = {};
            for (var song in allSongs) {
              String album = song.album ?? "Inconnu";
              if (!albumMap.containsKey(album)) albumMap[album] = [];
              albumMap[album]!.add(song);
            }
            List<String> albumList = albumMap.keys.toList()..sort();

            return GridView.builder(
              key: const PageStorageKey("albums_grid"),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemCount: albumList.length,
              itemBuilder: (context, index) {
                String name = albumList[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedAlbumName = name),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: QueryArtworkWidget(
                            //artworkWidth: 150,
                            id: albumMap[name]!.first.id,
                            type: ArtworkType.AUDIO,
                            artworkFit: BoxFit.cover,
                            artworkBorder: BorderRadius.circular(15),
                            nullArtworkWidget: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Center(
                                child: const Icon(Icons.album,
                                    color: Color(0xFFA838FF), size: 50),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("${albumMap[name]!.length} titres",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12)),
                    ],
                  ),
                );
              },
            );
          } else {
            // AFFICHER LES SONS DE L'ALBUM SÉLECTIONNÉ

            List<SongModel> albumSongs = allSongs
                .where((s) => (s.album ?? "Inconnu") == _selectedAlbumName)
                .toList();

            albumSongs.sort((a, b) {
              int trackA = a.track ?? 0;
              int trackB = b.track ?? 0;
              return trackA.compareTo(trackB);
            });
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.arrow_back, color: Colors.white),
                  title: Text(_selectedAlbumName!,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () => setState(() => _selectedAlbumName = null),
                ),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                    itemCount: albumSongs.length,
                    itemBuilder: (context, index) =>
                        _buildSongItem(albumSongs[index], albumSongs, index),
                  ),
                ),
              ],
            );
          }
        }
        // --- SCÉNARIO E : PLAYLISTS (Catégorie Index 4) ---
        if (_selectedCategoryIndex == 4) {
          if (selectedPlaylistName == null) {
            // AFFICHER LA LISTE DES PLAYLISTS
            if (playlistNames.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.queue_music_outlined,
                        color: Colors.white24, size: 60),
                    SizedBox(height: 10),
                    Text("Aucune playlist",
                        style: TextStyle(color: Colors.white54)),
                    SizedBox(height: 8),
                    // TextButton(
                    //   onPressed: () => _showPlaylistBottomSheet(context, null),
                    //   child: Text("Créer la première",
                    //       style: TextStyle(color: Color(0xFFA838FF))),
                    // ),
                  ],
                ),
              );
            }

            return GridView.builder(
              key: const PageStorageKey("playlists_grid"),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
              ),
              itemCount: playlistNames.length,
              itemBuilder: (context, index) {
                final name = playlistNames[index];
                return FutureBuilder<List<String>>(
                  future: PlaylistManager().getPlaylistSongs(name),
                  builder: (ctx, snapshot) {
                    final songCount = snapshot.data?.length ?? 0;

                    
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedPlaylistName = name),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.queue_music,
                                        color: Color(0xFFA838FF),
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text("$songCount titres",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12)),
                              ],
                            ),
                            // Bouton more_vert en haut à droite
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 18),
                                onSelected: (value) async {
                                  if (value == "rename") {
                                    final success =
                                        await _showRenamePlaylistDialog(name);
                                    if (success) {
                                      _loadPlaylistNames(); // Recharger la liste
                                    }
                                  } else if (value == "delete") {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor:
                                            const Color(0xFF2A273A),
                                        title: const Text(
                                            "Supprimer la playlist",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        content: Text("Supprimer '$name' ?",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Annuler",
                                                style: TextStyle(
                                                    color: Colors.white54)),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Supprimer",
                                                style: TextStyle(
                                                    color: Color(0xFFA838FF))),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await PlaylistManager()
                                          .deletePlaylist(name);
                                      playlistNames.remove(name);
                                      if (selectedPlaylistName == name) {
                                        selectedPlaylistName = null;
                                      }
                                      setState(() {});
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: "rename",
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text("Renommer",
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text("Supprimer",
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                                color: const Color(0xFF2A273A),
                                elevation: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                  
                  },
                );
              },
            );
          } else {
            // AFFICHER LES SONS DE LA PLAYLIST SÉLECTIONNÉE
            return FutureBuilder<List<String>>(
              future: PlaylistManager().getPlaylistSongs(selectedPlaylistName!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFA838FF)));
                }

                final songIds = snapshot.data ?? [];
                if (songIds.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          title: Text(selectedPlaylistName!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          onTap: () =>
                              setState(() => selectedPlaylistName = null),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.music_note_outlined,
                                color: Colors.white24, size: 60),
                            SizedBox(height: 10),
                            Text("Aucun morceau dans cette playlist",
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<List<SongModel>>(
                  future: _songsFuture, // Réutilise ta liste complète
                  builder: (ctx, songSnapshot) {
                    if (!songSnapshot.hasData) return const SizedBox.shrink();

                    final allSongs = songSnapshot.data!;
                    final playlistSongs = allSongs
                        .where((s) => songIds.contains(s.id.toString()))
                        .toList();

                    return Column(
                      children: [
                        // Bouton retour
                        ListTile(
                          leading:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          title: Text(selectedPlaylistName!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          onTap: () =>
                              setState(() => selectedPlaylistName = null),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 120),
                            itemCount: playlistSongs.length,
                            itemBuilder: (context, index) => _buildSongItem(
                                playlistSongs[index], playlistSongs, index),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }
        }

        // --- SCÉNARIO D : VUE PAR DÉFAUT (ALL SONGS - Index 0) ---
        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
          itemCount: allSongs.length,
          itemBuilder: (context, index) =>
              _buildSongItem(allSongs[index], allSongs, index),
        );
      },
    );
  }

// Extraction du Widget de la ligne de musique pour la réutilisation
  Widget _buildSongItem(SongModel song, List<SongModel> playlist, int index) {
    bool isCurrentSong = _playingSongId == song.id;

    return InkWell(
      onTap: () async {
        setState(() {
          currentPlaylist = List.from(playlist);
          currentIndex = index;
        });
        await _togglePlay(song, true);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  //borderRadius: BorderRadius.circular(12),
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFA838FF).withOpacity(0.8),
                      const Color(0xFF2A273A)
                    ],
                  ),
                ),
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrentSong
                          ? const Color(0xFFA838FF)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
            Text(
              _formatDuration(song.duration),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            // Bouton Play/Pause rapide
            GestureDetector(
              onTap: () {
                setState(() {
                  currentPlaylist = List.from(playlist);
                  currentIndex = index;
                });
                _togglePlay(song, false);
              },
              child: Icon(
                isCurrentSong && isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: isCurrentSong
                    ? const Color(0xFFA838FF)
                    : Colors.white.withOpacity(0.3),
                size: 25,
              ),
            ),
            const SizedBox(width: 8),
            // Bouton MORE (popup menu)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              onSelected: (value) async {
                if (value == "add_to_queue") {
                  // Ajouter à la fin de la liste de lecture
                  setState(() {
                    if (!currentPlaylist.contains(song)) {
                      currentPlaylist.add(song);
                    }
                  });
                } else if (value == "play_next") {
                  // Ajouter comme prochaine lecture (après la chanson actuelle)
                  if (currentSong != null && currentPlaylist.isNotEmpty) {
                    print("Okkkk");
                    final currentIndexInPlaylist =
                        currentPlaylist.indexOf(currentSong!);
                    if (currentIndexInPlaylist != -1) {
                      print("index playlist: ${currentIndexInPlaylist}");
                      setState(() {
                        final nextIndex = currentIndexInPlaylist + 1;

                        currentPlaylist.insert(nextIndex, song);
                      });
                    }
                  }
                } else if (value == "add_to_favorites") {
                  // Ajouter/retirer des favoris
                  setState(() {
                    final idStr = song.id.toString();
                    if (likedSongIds.contains(idStr)) {
                      likedSongIds.remove(idStr);
                    } else {
                      likedSongIds.add(idStr);
                    }
                  });
                  await saveLikedSongs();
                } else if (value == "add_to_playlist") {
                  debugPrint(
                      "Ouvrir l'écran de sélection de playlist pour ${song.title}");
                  final selectedPlaylistName =
                      await _showPlaylistBottomSheet(context, song);
                  if (selectedPlaylistName != null) {
                    final playlistManager = PlaylistManager();
                    await playlistManager.addSongToPlaylist(
                        selectedPlaylistName, song.id.toString());
                    debugPrint(
                        "Musique ajoutée à la playlist '${selectedPlaylistName}': ${song.title}");
                    _loadPlaylistNames();
                  }
                } else if (value == "delete_to_playlist" &&
                    _selectedCategoryIndex == 4 &&
                    selectedPlaylistName != null) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF2A273A),
                      title: const Text("Retirer de la playlist",
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                          "Retirer '${song.title}' de '${selectedPlaylistName}' ?",
                          style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Annuler",
                              style: TextStyle(color: Colors.white54)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Retirer",
                              style: TextStyle(color: Color(0xFFA838FF))),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final playlistManager = PlaylistManager();
                    await playlistManager.removeSongFromPlaylist(
                        selectedPlaylistName!, song.id.toString());

                    
                      setState(() {
                        _loadPlaylistNames();
                      });
                    

                    // Feedback visuel
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Retiré de '${selectedPlaylistName}'"),
                          backgroundColor: const Color(0xFF2A273A),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "add_to_queue",
                  child: Text(
                    "Ajouter à la liste de lecture",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: "play_next",
                  child: Text(
                    "Lecture suivante",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: "add_to_favorites",
                  child: Text(
                    likedSongIds.contains(song.id.toString())
                        ? "Retirer des favoris"
                        : "Ajouter aux favoris",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: "add_to_playlist",
                  child: Text(
                    "Ajouter à une playlist",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_selectedCategoryIndex == 4 && selectedPlaylistName != null)
                  PopupMenuItem(
                    value: "delete_to_playlist",
                    child: Text(
                      "Retirer de la playlist",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
              color: const Color(0xFF2A273A),
              elevation: 8,
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showPlaylistBottomSheet(
    BuildContext context,
    SongModel song,
  ) async {
    final controller = TextEditingController();
    final PlaylistManager manager = PlaylistManager();

    final GlobalKey<FormState> formKey = GlobalKey();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      backgroundColor: const Color(0xFF120E2B),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ajouter à une playlist",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                hintText: "Créer une nouvelle playlist",
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2A273A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed:
                                      null, // on gère dans le bouton en dessous
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "Veuillez saisir un nom";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final name = controller.text.trim();
                                final bool success =
                                    await manager.createPlaylist(name);
                                if (success) {
                                  controller.clear();
                                  setState(() {});
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFA838FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: const Text(
                              "Créer",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Sélectionner une playlist",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: FutureBuilder<List<String>>(
                          future: manager.getPlaylistNames(),
                          builder: (ctx, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFA838FF),
                                ),
                              );
                            }

                            final playlists = snapshot.data ?? <String>[];

                            if (playlists.isEmpty) {
                              return Center(
                                child: Text(
                                  "Aucune playlist",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: playlists.length,
                              itemBuilder: (ctx, i) {
                                final name = playlists[i];
                                final nbSongs = playlists[i].length;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.queue_music,
                                      color: Color(0xFFA838FF),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  //subtitle: Text("$nbSongs"),
                                  onTap: () {
                                    Navigator.pop(ctx, name);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _showRenamePlaylistDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    return await showDialog<bool>(
          context: context,
          // isScrollControlled: true,
          // shape: const RoundedRectangleBorder(
          //   borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          // ),
          // backgroundColor: const Color(0xFF120E2B),
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF120E2B),
            content: Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom)
                      .copyWith(top: 20, left: 16, right: 16, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Renommer la playlist",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Nouveau nom",
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2A273A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Annuler",
                              style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA838FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final newName = controller.text.trim();
                            final success = await PlaylistManager()
                                .renamePlaylist(currentName, newName);
                            if (success) {
                              playlistNames.remove(currentName);
                              playlistNames.add(newName);
                              setState(() {});
                            }
                            Navigator.pop(ctx, success);
                          },
                          child: const Text("Renommer",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }
}
