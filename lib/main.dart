import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:musicappplayer/audiohandler..dart';
import 'package:musicappplayer/musicplayerscreen.dart';
import 'package:musicappplayer/songhandler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

SongHandler _songHandler = SongHandler(); // Singleton instance of AudioHandler.

Future<void> main() async {
  // Ensure Widgets are bound before initializing the audio handler.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AudioService with your custom AudioPlayerHandler.
  _songHandler = await AudioService.init(
    builder: () => SongHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Provide the SongsProvider with the loaded songs and SongHandler
        ChangeNotifierProvider(
          create: (context) => SongsProvider()..loadSongs(_songHandler),
        ),
      ],
      // Use the MainApp widget as the root of the application
      child: const MaterialApp(
        home: Songs(),
      ),
    ),
  );
}

class Songs extends StatefulWidget {
  const Songs({Key? key}) : super(key: key);

  @override
  _SongsState createState() => _SongsState();
}

class _SongsState extends State<Songs> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission =
      false; // Indicates whether the app has permission to access audio files.

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  // Method to check and request necessary permissions to access the audio library.
  Future<void> _checkAndRequestPermissions({bool retry = false}) async {
    _hasPermission = await _audioQuery.permissionsStatus();

    if (!_hasPermission) {
      _hasPermission = await _audioQuery.permissionsRequest();
    }

    if (_hasPermission) {
      setState(() {}); // Update the UI when permissions are granted.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Player"),
        elevation: 2,
      ),
      body: Consumer<SongsProvider>(builder: (context, songsProvider, _) {
        return Center(
            child: songsProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: songsProvider.songs.length,
                    itemBuilder: (context, index) {
                      MediaItem song = songsProvider.songs[index];

                      return ListTile(
                        title: Text(song.title),
                        subtitle: Text(song.artist ?? "Unknown Artist"),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        leading: QueryArtworkWidget(
                          controller: _audioQuery,
                          id: int.parse(song.displayDescription!),
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: const Icon(Icons
                              .music_note), // Default icon if no artwork is found.
                        ),
                        onTap: () async {
                          await _songHandler.skipToQueueItem(
                              songsProvider.songs.indexOf(song));
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MusicPlayerScreen(
                                      songHandler: _songHandler)));
                        },
                      );
                    },
                  ));
      }),
    );
  }

  // Widget to show when access to the music library is not available.
  Widget _noAccessToLibraryWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Permission to access music library denied."),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _checkAndRequestPermissions,
          child: const Text("Request Permission"),
        ),
      ],
    );
  }
}

 // Display the list of songs.
                    