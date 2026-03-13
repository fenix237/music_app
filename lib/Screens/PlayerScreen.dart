import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../Services/LikedSongs.dart';
import '../Services/RecentSongs.dart';
import '../Utils/Globals.dart';

class PlayerScreen extends StatefulWidget {
  final List<SongModel> songs; // Liste des chansons
  final int currentIndex; // Index actuel
  final AudioPlayer player;

  const PlayerScreen({
    Key? key,
    required this.songs,
    required this.currentIndex,
    required this.player,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // --- NOUVELLES VARIABLES D'ÉTAT ---

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;

    // On sauvegarde la souscription pour pouvoir l'annuler à la fermeture de l'écran
    playerStateSubscription = widget.player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongEnd();
      }
    });
  }

  @override
  void dispose() {
    // Évite les fuites de mémoire et les sauts de musique multiples
    playerStateSubscription?.cancel();
    super.dispose();
  }

  // --- LOGIQUE DE LECTURE ---

  void _handleSongEnd() {
    if (repeatMode == 2) {
      // Si "Répéter un titre", on relance le même index
      _loadSong(currentIndex);
    } else {
      // Sinon, comportement normal de passage au suivant (qui inclut le shuffle)
      _skipNext();
    }
  }

  void _toggleShuffle() {
    setState(() {
      isShuffle = !isShuffle;
    });
  }

  void _toggleRepeat() {
    setState(() {
      repeatMode = (repeatMode + 1) % 3; // Passe de 0 -> 1 -> 2 -> 0...
    });
  }

  Future<void> _toggleLike(int songId) async {
    setState(() {
      String idStr = songId.toString();
      if (likedSongIds.contains(idStr)) {
        likedSongIds.remove(idStr);
      } else {
        likedSongIds.add(idStr);
      }
    });
    saveLikedSongs();
    List<String> likd = await loadLikedSongs();
    print("La taille des liked songs après toggle: ${likd.length}");
  }

  Future<void> _loadSong(int index) async {
    if (index < 0 || index >= widget.songs.length) return;

    setState(() {
      currentIndex = index;
    });

    try {
      final song = widget.songs[currentIndex];
      await addToRecent(song.id.toString());
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

      await widget.player.setAudioSource(source);
      widget.player.play();
    } catch (e) {
      debugPrint("Erreur changement morceau : $e");
    }
  }

  void _skipNext() {
    if (isShuffle) {
      // S'il n'y a qu'une seule chanson, on ne fait rien de spécial
      if (widget.songs.length <= 1) return;

      int nextIndex;
      do {
        nextIndex = Random().nextInt(widget.songs.length);
      } while (
          nextIndex == currentIndex); // S'assure qu'on ne rejoue pas la même

      _loadSong(nextIndex);
    } else {
      if (currentIndex < widget.songs.length - 1) {
        _loadSong(currentIndex + 1);
      } else  {
        _loadSong(0);
      }  
      // } else if (repeatMode == 1) {
      //   // Si on est à la fin et que "Répéter tout" est actif, on retourne au début
      //   _loadSong(0);
      // }
    }
  }

  void _skipPrevious() {
    if (isShuffle) {
      // En mode aléatoire, "précédent" choisit aussi une chanson au hasard
      _skipNext();
    } else {
      if (currentIndex > 0) {
         print("next *************************");
        _loadSong(currentIndex - 1);
      } else  {
        print("next *************************");
        _loadSong(widget.songs.length - 1);
      }
      // } else if (repeatMode == 1) {
      //   // Si on est au début et que "Répéter tout" est actif, on va à la fin
      //   _loadSong(widget.songs.length - 1);
      // }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "0:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[currentIndex];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E3A6D), Color(0xFF120E2B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildAppBar(context),
              const Spacer(),
              _buildStaticAlbumArt(currentSong.id),
              const Spacer(),
              _buildSongInfo(currentSong),
              const SizedBox(height: 30),
              _buildProgressSlider(),
              const SizedBox(height: 40),
              _buildControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final currentSong = widget.songs[currentIndex];
    final isLiked = likedSongIds.contains(currentSong.id.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIcon(Icons.keyboard_arrow_down, Colors.white,
              () => Navigator.pop(context)),
          const Text('Now Playing',
              style: TextStyle(color: Colors.white, letterSpacing: 1)),
          Row(
            children: [
              _buildCircleIcon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  isLiked ? const Color(0xFFA838FF) : Colors.white,
                  () => _toggleLike(currentSong.id)),
                  SizedBox(width: 8,),
              _buildCircleIcon(Icons.more_vert, Colors.white, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
            shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildStaticAlbumArt(int songId) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA838FF).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkWidth: 280,
          artworkHeight: 280,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: Container(
            color: Colors.white10,
            child: const Icon(Icons.music_note, color: Colors.white, size: 100),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(SongModel song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Text(
            song.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            song.artist ?? "Unknown Artist",
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.player.duration ?? Duration.zero;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbColor: const Color(0xFFA838FF),
                  activeTrackColor: const Color(0xFFA838FF),
                  inactiveTrackColor: Colors.white12,
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  min: 0,
                  max: duration.inMilliseconds.toDouble(),
                  value: position.inMilliseconds
                      .toDouble()
                      .clamp(0, duration.inMilliseconds.toDouble()),
                  onChanged: (value) {
                    widget.player.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position),
                        style: const TextStyle(color: Colors.white54)),
                    Text(_formatDuration(duration),
                        style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // BOUTON SHUFFLE
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: isShuffle ? const Color(0xFFA838FF) : Colors.white54,
            ),
            iconSize: 28,
            onPressed: _toggleShuffle,
          ),

          // BOUTON PRÉCÉDENT
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
            iconSize: 45,
            // Reste actif si on est en boucle, en aléatoire, ou pas au début
            onPressed: (currentIndex > 0 || repeatMode == 1 || isShuffle)
                ? _skipPrevious
                : null,
          ),

          // PLAY / PAUSE
          StreamBuilder<bool>(
            stream: widget.player.playingStream,
            builder: (context, snapshot) {
              final playing = snapshot.data ?? false;
              return GestureDetector(
                onTap: () {
                  playing ? widget.player.pause() : widget.player.play();
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 45,
                  ),
                ),
              );
            },
          ),

          // BOUTON SUIVANT
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
            iconSize: 45,
            // Reste actif si on est en boucle, en aléatoire, ou pas à la fin
            onPressed: (currentIndex < widget.songs.length - 1 ||
                    repeatMode == 1 ||
                    isShuffle)
                ? _skipNext
                : null,
          ),

          // BOUTON REPEAT
          IconButton(
            icon: Icon(
              repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
              color: repeatMode != 0 ? const Color(0xFFA838FF) : Colors.white54,
            ),
            iconSize: 28,
            onPressed: _toggleRepeat,
          ),
        ],
      ),
    );
  }
}
