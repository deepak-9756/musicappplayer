import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';

import 'package:flutter/material.dart';
import 'package:musicappplayer/audiohandler..dart';
import 'package:on_audio_query/on_audio_query.dart';

// Define a class for managing songs using ChangeNotifier
class SongsProvider extends ChangeNotifier {
  // Private variable to store the list of songs
  List<MediaItem> _songs = [];

  // Getter for accessing the list of songs
  List<MediaItem> get songs => _songs;

  // Private variable to track the loading state
  bool _isLoading = true;

  // Getter for accessing the loading state
  bool get isLoading => _isLoading;

  // Asynchronous method to load songs
  Future<void> loadSongs(SongHandler songHandler) async {
    try {
      // Use the getSongs function to fetch the list of songs
      _songs = await getSongs();

      // Initialize the song handler with the loaded songs
      await songHandler.initSongs(songs: _songs);

      // Update the loading state to indicate completion
      _isLoading = false;

      // Notify listeners about the changes in the state
      notifyListeners();
    } catch (e) {
      // Handle any errors that occur during the process
      debugPrint('Error loading songs: $e');
      // You might want to set _isLoading to false here as well, depending on your use case
    }
  }

  // Asynchronous function to get a list of MediaItems representing songs
  Future<List<MediaItem>> getSongs() async {
    try {
      // List to store the MediaItems representing songs
      final List<MediaItem> songs = [];

      // Create an instance of OnAudioQuery for querying songs
      final OnAudioQuery onAudioQuery = OnAudioQuery();

      // Query the device for song information using OnAudioQuery
      final List<SongModel> songModels = await onAudioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      // Convert each SongModel to a MediaItem and add it to the list of songs
      for (final SongModel songModel in songModels) {
        final MediaItem song = await songToMediaItem(songModel);
        songs.add(song);
      }

      // Return the list of songs
      return songs;
    } catch (e) {
      // Handle any errors that occur during the process
      debugPrint('Error fetching songs: $e');
      return []; // Return an empty list in case of error
    }
  }

  // Convert a SongModel to a MediaItem
  Future<MediaItem> songToMediaItem(SongModel song) async {
    try {
      // Get the artwork for the song
      // final Uri? art = await getSongArt(
      //   id: song.id,
      //   type: ArtworkType.AUDIO,
      //   quality: 100,
      //   size: 300,
      // );
      //  print("vghjfkdn$art");

      // Create and return a MediaItem
      return MediaItem(
        // Use the song URI as the MediaItem ID
        id: song.uri.toString(),

        // Set the artwork URI obtained earlier
        artUri: Uri.parse(
            "https://imgs.search.brave.com/zNellKu19Nwc96VIEgcRB7czQqkgNaQvxiMswn0j28o/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWFn/ZXMuY3RmYXNzZXRz/Lm5ldC9ocmx0eDEy/cGw4aHEvNE4xTmVv/SFRhVDhuSTB4N3Ax/akNHay81YTYwNTRh/NTA0NmI3NzQ5YTZi/NzhhZDNjYTFlYjU3/Zi93YXRlci1zcGxh/c2gtY2xyLXNodXR0/ZXJzdG9ja18yNTg0/MjE4MDUuanBnP2Zp/dD1maWxsJnc9NDgw/Jmg9Mjcw"),

        // Format the song title using the provided utility function
        title: formattedTitle(song.title).trim(),

        // Set the artist, duration, and display description
        artist: song.artist,
        duration: Duration(milliseconds: song.duration!),
        displayDescription: song.id.toString(),
      );
    } catch (e) {
      // Handle any errors that occur during the process
      debugPrint('Error converting SongModel to MediaItem: $e');
      // Return a default or null MediaItem in case of an error
      return const MediaItem(id: '', title: 'Error', artist: 'Unknown');
    }
  }
}

// Clean up a title string by removing content within parentheses, brackets, and file extensions
String formattedTitle(String title) {
  // Make a copy of the original title
  String cleanedTitle = title;

  // Remove content within parentheses
  cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\([^)]*\)'), '');

  // Remove content within brackets
  cleanedTitle = cleanedTitle.replaceAll(RegExp(r'\[[^\]]*\]'), '');

  // Remove file extension (if present)
  if (cleanedTitle.contains('.')) {
    // Remove everything after the first '.'
    cleanedTitle = cleanedTitle.split('.').first;
  }

  // Return the cleaned-up title
  return cleanedTitle;
}

// Asynchronous function to get the artwork for a song
Future<Uri?> getSongArt({
  required int id,
  required ArtworkType type,
  required int quality,
  required int size,
}) async {
  try {
    // Create an instance of OnAudioQuery for querying artwork
    final OnAudioQuery onAudioQuery = OnAudioQuery();

    // Query artwork data for the specified song
    final Uint8List? data = await onAudioQuery.queryArtwork(
      id,
      type,
      quality: quality,
      format: ArtworkFormat.JPEG,
      size: size,
    );

    // Variable to store the artwork's Uri
    Uri? art;

    // Check if artwork data is not null
    if (data != null) {
      // Create a temporary directory to store the artwork file
      final Directory tempDir = Directory.systemTemp;

      // Create a file in the temporary directory with the song's id as the filename
      final File file = File("${tempDir.path}/$id.jpg");

      // Write the artwork data to the file
      await file.writeAsBytes(data);

      // Set the artwork variable to the Uri of the created file
      art = file.uri;
    }

    // Return the artwork's Uri
    return art;
  } catch (e) {
    // Handle any errors that occur during the process
    debugPrint('Error fetching song artwork: $e');
    return null; // Return null in case of error
  }
}
