import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_app/Screens/Library.dart';
import '../Utils/Globals.dart';
import 'HomePage.dart';
import 'SettingsScreen.dart';
import 'PlayerScreen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => isPlaying = state.playing);
    });

    audioPlayer.sequenceStateStream.listen((state) {
      final tag = state?.currentSource?.tag;
      if (tag != null && mounted) {

      }
    });
  }

  void _playSong(SongModel song) {
    setState(() {
      currentSong = song;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120E2B),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentPageIndex,
            children:  [
              HomeScreen(onTapSearch: () =>
                setState(() {
                  isVisibleSearch = true;
                  _currentPageIndex = 1;
                })
              ,),
              LibraryScreen(), 
              SettingsScreen(),
            ],
          ),

          _buildGlobalMiniPlayer(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildGlobalMiniPlayer() {
    if (currentSong == null) return const SizedBox.shrink();
    setState(() {
      currentIndex = currentPlaylist.indexOf(currentSong!);
    });

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
            StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      key: ValueKey<bool>(isPlaying),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  onPressed: () {
                    playing ? audioPlayer.pause() : audioPlayer.play();
                  },
                );
              },
            ),
            const SizedBox(width: 4),
          ]),
        ),
      ),
    );
  }

  // Ta barre de navigation (inchangée mais mise dans une fonction pour la clarté)
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A273A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled),
            _buildNavItem(1, Icons.music_note_outlined),
            _buildNavItem(2, Icons.settings_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isActive = _currentPageIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentPageIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        padding: const EdgeInsets.all(12),
        decoration: isActive
            ? const BoxDecoration(
                color: Color(0xFFA838FF), shape: BoxShape.circle)
            : null,
        child: Icon(icon,
            color: isActive ? Colors.white : Colors.white54, size: 28),
      ),
    );
  }
}
