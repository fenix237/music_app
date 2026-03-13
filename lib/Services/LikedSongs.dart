import 'package:shared_preferences/shared_preferences.dart';

List<String> likedSongIds = []; 

Future<void> saveLikedSongs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('likedSongs', likedSongIds);
}

Future<List<String>> loadLikedSongs() async {
  final prefs = await SharedPreferences.getInstance();
  likedSongIds = prefs.getStringList('likedSongs') ?? [];
  print("LA TAILLLE:  ${likedSongIds.length}");
  return likedSongIds;
}