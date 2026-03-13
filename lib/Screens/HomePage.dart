import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

// N'oublie pas d'importer tes vrais services !
import '../Services/LikedSongs.dart';
import '../Services/RecentSongs.dart';
import '../Utils/Globals.dart';
import 'PlayerScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  bool _isLoading = true;
  List<SongModel> _forYouSongs = [];
  List<SongModel> _recentSongs = [];

  // --- VARIABLES LECTURE (Mini-Player) ---
  int? _playingSongId;
  int _currentIndex = -1;
  StreamSubscription? _playerStateSubscription;

  final List<String> _randomMessages = [
    "Feel the Beat",
    "Just For You",
    "Discover New Sounds",
    "Vibe Out Today",
    "Your Daily Mix",
    "Chill Vibes",
    "Turn Up The Volume"
  ];

  @override
  void initState() {
    super.initState();
    _initPlayerListeners();
    _loadHomeScreenData();
  }

  void _initPlayerListeners() {
    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => isPlaying = state.playing);
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
              _currentIndex = currentPlaylist.indexOf(currentSong!);
            } catch (e) {}
          }
        });
      }
    });
  }

  Future<void> _loadHomeScreenData() async {
    // 1. Récupérer toutes les chansons
    List<SongModel> allSongs = await audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    if (allSongs.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 2. Charger les données de tes services
    List<String> likedIds = await loadLikedSongs();
    List<String> recentIds = await loadRecentSongs();

    // Fonction utilitaire pour vérifier si le son a une cover
    Future<bool> hasCover(int id) async {
      final Uint8List? art =
          await audioQuery.queryArtwork(id, ArtworkType.AUDIO, size: 50);
      return art != null && art.isNotEmpty;
    }

    // --- LOGIQUE "FOR YOU" (5 chansons avec cover) ---
    List<SongModel> forYouPool = [];

    // Priorité 1 : Les favoris AVEC cover
    var likedSongs =
        allSongs.where((s) => likedIds.contains(s.id.toString())).toList();
    likedSongs.shuffle();
    for (var song in likedSongs) {
      if (forYouPool.length >= 5) break;
      if (await hasCover(song.id)) forYouPool.add(song);
    }

    // Priorité 2 : Récents AVEC cover (pour combler)
    if (forYouPool.length < 5) {
      var recents = allSongs
          .where((s) =>
              recentIds.contains(s.id.toString()) && !forYouPool.contains(s))
          .toList();
      for (var song in recents) {
        if (forYouPool.length >= 5) break;
        if (await hasCover(song.id)) forYouPool.add(song);
      }
    }

    // Priorité 3 : Sons aléatoires AVEC cover (pour combler)
    if (forYouPool.length < 5) {
      var others = allSongs.where((s) => !forYouPool.contains(s)).toList();
      others.shuffle();
      for (var song in others) {
        if (forYouPool.length >= 5) break;
        if (await hasCover(song.id)) forYouPool.add(song);
      }
    }

    // On mélange le résultat final pour que ce soit dynamique à chaque ouverture
    _forYouSongs = forYouPool;
    _forYouSongs.shuffle();

    // --- LOGIQUE "RECENT" (Historique exact en bas) ---
    List<SongModel> recentsList = [];
    if (recentIds.length >= 10) {
      recentIds = recentIds.sublist(0, 10);
    }
    for (String id in recentIds) {
      try {
        var song = allSongs.firstWhere((s) => s.id.toString() == id);
        if (!recentsList.contains(song)) recentsList.add(song);
      } catch (e) {
        // Le son n'existe plus sur le téléphone, on l'ignore
      }
    }

    _recentSongs = recentsList;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlay(
      SongModel song, List<SongModel> playlistContext, int index) async {
    if (song.uri == null) return;

    setState(() {
      currentPlaylist = playlistContext;
      _currentIndex = index;
    });

    if (_playingSongId == song.id) {
      if (isPlaying) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } else {
      // Nouveau son : On lance la lecture
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

      // On sauvegarde en temps réel via ton nouveau service !
      await addToRecent(song.id.toString());
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120E2B),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA838FF)))
            else
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildGreeting(),
                    // const SizedBox(height: 24),
                    // _buildCategoryChips(),
                    const SizedBox(height: 30),
                    _buildForYouSection(),
                    const SizedBox(height: 30),
                    _buildRecentSection(),
                  ],
                ),
              ),
            // LE MINI-PLAYER
           // _buildMiniPlayer(),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: () {},
      ),
    );
  }

  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Hello, Kyser',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'New Artists', 'Hot Tracks', 'Editor\'s Picks'];

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

  Widget _buildForYouSection() {
    if (_forYouSongs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'For you',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _forYouSongs.asMap().entries.map((entry) {
              return _buildForYouCard(entry.value, entry.key);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildForYouCard(SongModel song, int index) {
    String randomMsg =
        _randomMessages[Random().nextInt(_randomMessages.length)];
    bool isCurrentSong = _playingSongId == song.id;

    return Container(
      width: 320,
      height: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA838FF), Color(0xFF4B66EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.music_note,
                    size: 80, color: Colors.white30),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    randomMsg,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 200,
                    child: Text(
                      "${song.title}\npar ${song.artist ?? 'Inconnu'}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _togglePlay(song, _forYouSongs, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentSong && isPlaying
                          ? const Color(0xFFA838FF)
                          : Colors.white.withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(
                        isCurrentSong && isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 18),
                    label: Text(
                        isCurrentSong && isPlaying
                            ? 'Playing...'
                            : 'Start Listening',
                        style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    if (_recentSongs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              // Text('Show all >',
              //     style: TextStyle(
              //         fontSize: 14, color: Colors.white.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSongs.length,
            itemBuilder: (context, index) {
              final track = _recentSongs[index];
              bool isCurrentSong = _playingSongId == track.id;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _togglePlay(track, _recentSongs, index),
                leading: QueryArtworkWidget(
                  id: track.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(12),
                  artworkWidth: 50,
                  artworkHeight: 50,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A273A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
                title: Text(track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCurrentSong
                            ? const Color(0xFFA838FF)
                            : Colors.white)),
                subtitle: Text(track.artist ?? "Inconnu",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13)),
                trailing: IconButton(
                  icon: Icon(
                    isCurrentSong && isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  color:
                      isCurrentSong ? const Color(0xFFA838FF) : Colors.white54,
                  iconSize: 32,
                  onPressed: () => _togglePlay(track, _recentSongs, index),
                ),
              );
            },
          )
        ],
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
                currentIndex: _currentIndex,
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
                  offset: const Offset(0, 5)),
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
                        fontSize: 15),
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
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                if (isPlaying) {
                  audioPlayer.pause();
                } else {
                  audioPlayer.play();
                }
              },
            ),
            const SizedBox(width: 4),
          ]),
        ),
      ),
    );
  }
}
