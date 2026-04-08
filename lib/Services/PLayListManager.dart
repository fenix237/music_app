import 'package:shared_preferences/shared_preferences.dart';

class PlaylistManager {
  static const String _keyPlaylistNames = 'playlistNames';

  /// Liste de tous les noms de playlists
  Future<List<String>> getPlaylistNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyPlaylistNames) ?? [];
  }

  /// Créer une nouvelle playlist
  Future<bool> createPlaylist(String name) async {
    if (name.trim().isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_keyPlaylistNames) ?? [];

    if (names.contains(name)) {
      return false; // Playlist déjà existante
    }

    names.add(name);
    await prefs.setStringList(_keyPlaylistNames, names);

    // Créer la liste de sons vide pour cette playlist
    await prefs.setStringList('playlist_$name', []);
    return true;
  }

  /// Supprimer une playlist
  Future<void> deletePlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(_keyPlaylistNames) ?? [];

    names.remove(name);
    await prefs.setStringList(_keyPlaylistNames, names);
    await prefs.remove('playlist_$name');
  }

  /// Charger les sons d’une playlist
  Future<List<String>> getPlaylistSongs(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('playlist_$name') ?? [];
  }

  /// Ajouter un morceau à une playlist
  Future<void> addSongToPlaylist(String playlistName, String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = prefs.getStringList('playlist_$playlistName') ?? [];

    if (!songs.contains(songId)) {
      songs.add(songId);
      await prefs.setStringList('playlist_$playlistName', songs);
    }
  }

  /// Retirer un morceau d’une playlist
  Future<void> removeSongFromPlaylist(String playlistName, String songId) async {
      final prefs = await SharedPreferences.getInstance();
      final songs = prefs.getStringList('playlist_$playlistName') ?? [];

      songs.remove(songId);
      await prefs.setStringList('playlist_$playlistName', songs);
  }

  /// Rechercher des playlists par nom (match partiel)
  Future<List<String>> searchPlaylists(String query) async {
    if (query.trim().isEmpty) return await getPlaylistNames();

    final allNames = await getPlaylistNames();
    final lowerQuery = query.toLowerCase();

    return allNames
        .where((name) => name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}