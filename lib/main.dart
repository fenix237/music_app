import 'package:flutter/material.dart';
import 'package:music_app/Screens/Library.dart';
import 'package:music_app/Screens/Playing.dart';

import 'Screens/HomePage.dart';
import 'Utils/Theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
     debugShowCheckedModeBanner: false,
     theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120E2B), // Couleur de fond sombre
        fontFamily: 'Roboto', // Vous pouvez utiliser Google Fonts pour plus de précision
      ),
      //theme: themeData,
     home: const PlayerScreen(),
    );
  }
}

