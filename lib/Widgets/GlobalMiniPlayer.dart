// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:music_app/Screens/Library.dart';
// import '../Screens/PlayerScreen.dart';
// import '../Utils/Globals.dart';

// class GlobalMiniPlayer extends StatefulWidget {
//   const GlobalMiniPlayer({super.key});

//   @override
//   State<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
// }

// class _GlobalMiniPlayerState extends State<GlobalMiniPlayer> {
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: GestureDetector(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlayerScreen(
//                 songs: currentPlaylist,
//                 currentIndex: currentIndex,
//                 player: _audioPlayer,
//               ),
//             ),
//           ).then((value) => setState(() {}));
//         },
//         child: Container(
//           margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: const Color(0xFF2A273A),
//             borderRadius: BorderRadius.circular(30),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 10,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: Row(children: [
//             QueryArtworkWidget(
//               id: currentSong!.id,
//               type: ArtworkType.AUDIO,
//               artworkFit: BoxFit.cover,
//               artworkWidth: 46,
//               artworkHeight: 46,
//               artworkBorder: BorderRadius.circular(23),
//               nullArtworkWidget: Container(
//                 width: 46,
//                 height: 46,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(23),
//                   color: const Color(0xFFA838FF).withOpacity(0.8),
//                 ),
//                 child:
//                     const Icon(Icons.music_note, color: Colors.white, size: 24),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     currentSong!.title,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
//                   ),
//                   Text(
//                     currentSong!.artist ?? "Artiste inconnu",
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                         color: Colors.white.withOpacity(0.6), fontSize: 13),
//                   ),
//                 ],
//               ),
//             ),
//             IconButton(
//               icon: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 transitionBuilder: (child, animation) =>
//                     ScaleTransition(scale: animation, child: child),
//                 child: Icon(
//                   _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//                   key: ValueKey<bool>(_isPlaying),
//                   color: Colors.white,
//                   size: 30,
//                 ),
//               ),
//               onPressed: () {
//                 if (globalAudioPlayer.audioSource != null) {
//                   if (_isPlaying) {
//                     globalAudioPlayer.pause();
//                   } else {
//                     globalAudioPlayer.play();
//                   }
//                 }
//               },
//             ),
//             const SizedBox(width: 4),
//           ]),
//         ),
//       ),
//     );;
//   }
// }