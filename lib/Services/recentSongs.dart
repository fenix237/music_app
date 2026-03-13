import 'package:shared_preferences/shared_preferences.dart';

List<String> recentSongIds = [];

Future<List<String>> loadRecentSongs() async {
  final prefs = await SharedPreferences.getInstance();
  recentSongIds = prefs.getStringList('recentSongs') ?? [];
  return recentSongIds;
}

Future<void> addToRecent(String songId) async {
  final prefs = await SharedPreferences.getInstance();

  recentSongIds = prefs.getStringList('recentSongs') ?? [];

  if (recentSongIds.contains(songId)) {
    recentSongIds.remove(songId);
  }

  recentSongIds.insert(0, songId);

  if (recentSongIds.length > 10) {
    recentSongIds.removeLast();
  }

  await prefs.setStringList('recentSongs', recentSongIds);
}

Future<void> clearRecentSongs() async {
  final prefs = await SharedPreferences.getInstance();
  recentSongIds.clear();
  await prefs.remove('recentSongs');
}
