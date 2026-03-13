import 'package:flutter/material.dart';
import 'package:music_app/Screens/Library.dart';
import 'package:music_app/Screens/PlayerScreen.dart';

import 'Screens/HomePage.dart';
import 'Screens/MainSreen.dart';
import 'Services/LikedSongs.dart';
import 'Utils/Theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio_background/just_audio_background.dart';


void main() async{
WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
 // await loadLikedSongs();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
     debugShowCheckedModeBanner: false,
    
      theme: themeData,
     home:  MainScreen(),
    );
  }
}

