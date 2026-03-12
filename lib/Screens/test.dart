import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'PlayerScreen.dart';
import '../Utils/Globals.dart'; // Ajuste le chemin selon ton projet

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
  SongModel? _currentSong;
  List<SongModel> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  String _searchText = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _songsFuture = _audioQuery.querySongs(
      ignoreCase: true,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    // Écoute des changements d'état du lecteur
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });

    // Écoute de l'index actuel pour mettre à jour le mini-player automatiquement
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentPlaylist.isNotEmpty && mounted) {
        setState(() {
          _currentIndex = index;
          _currentSong = _currentPlaylist[index];
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.audio.request();
    setState(() => _hasPermission = status.isGranted);
  }

  // Initialisation de la playlist complète pour just_audio
  Future<void> _handlePlay(List<SongModel> songs, int index) async {
    _currentPlaylist = songs;

    final playlist = ConcatenatingAudioSource(
      children: songs
          .map((song) => AudioSource.uri(
                Uri.parse(song.uri!),
                tag: MediaItem(
                  id: song.id.toString(),
                  album: song.album ?? "Album inconnu",
                  title: song.title,
                  artist: song.artist ?? "Artiste inconnu",
                  artUri: Uri.parse(
                      'content://media/external/audio/media/${song.id}/albumart'),
                ),
              ))
          .toList(),
    );

    await _audioPlayer.setAudioSource(playlist, initialIndex: index);

    // Application des variables globales au démarrage
    await _audioPlayer.setShuffleModeEnabled(isShuffle);
    _applyRepeatMode();

    _audioPlayer.play();
  }

  void _applyRepeatMode() {
    if (repeatMode == 1)
      _audioPlayer.setLoopMode(LoopMode.all);
    else if (repeatMode == 2)
      _audioPlayer.setLoopMode(LoopMode.one);
    else
      _audioPlayer.setLoopMode(LoopMode.off);
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
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PlayerScreen(
                    player: _audioPlayer,
                    songs: _currentPlaylist,
                    currentIndex: _currentIndex))),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFF2A273A),
              borderRadius: BorderRadius.circular(30)),
          child: Row(
            children: [
              QueryArtworkWidget(
                  id: _currentSong!.id,
                  type: ArtworkType.AUDIO,
                  artworkWidth: 46,
                  artworkHeight: 46,
                  artworkBorder: BorderRadius.circular(23)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_currentSong!.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30),
                onPressed: () =>
                    _isPlaying ? _audioPlayer.pause() : _audioPlayer.play(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS UI ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, color: Colors.white)),
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search,
                  color: Colors.white),
              onPressed: () => setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchText = "";
                  })),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _isSearching
          ? TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none),
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
            )
          : const Text('Your library',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
            children: ['All', 'Liked', 'Playlists']
                .map((e) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                        color: e == 'All'
                            ? const Color(0xFFA838FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24)),
                    child:
                        Text(e, style: const TextStyle(color: Colors.white))))
                .toList()));
  }

  Widget _buildRealSongList() {
    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA838FF)));
        final songs = snapshot.data!
            .where((s) => s.title.toLowerCase().contains(_searchText))
            .toList();
        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 110),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            bool isCurrent = _currentSong?.id == song.id;
            return ListTile(
              onTap: () => _handlePlay(songs, index),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: QueryArtworkWidget(id: song.id, type: ArtworkType.AUDIO),
              title: Text(song.title,
                  style: TextStyle(
                      color: isCurrent ? const Color(0xFFA838FF) : Colors.white,
                      fontWeight: FontWeight.bold),
                  maxLines: 1),
              subtitle: Text(song.artist ?? "Inconnu",
                  style: const TextStyle(color: Colors.white60)),
              trailing: isCurrent && _isPlaying
                  ? const Icon(Icons.bar_chart, color: Color(0xFFA838FF))
                  : null,
            );
          },
        );
      },
    );
  }
}
