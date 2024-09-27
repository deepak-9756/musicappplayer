import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicappplayer/songhandler.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Class for handling audio playback using AudioService and Just Audio
class SongHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  // Create an instance of the AudioPlayer class from just_audio package
  final AudioPlayer audioPlayer = AudioPlayer();

  // Function to create an audio source from a MediaItem
  UriAudioSource _createAudioSource(MediaItem item) {
    return ProgressiveAudioSource(Uri.parse(item.id));
  }

  // Listen for changes in the current song index and update the media item
  // void _listenForCurrentSongIndexChanges() {
  //   print("jkgflmd,");
  //   audioPlayer.currentIndexStream.listen((index) {
  //     print("jkgflmd,");
  //     final playlist = queue.value;
  //     if (index == null || playlist.isEmpty) return;
  //     mediaItem.add(playlist[index]);
  //   });
  // }

  // Listen for changes in the current song index and update the media item
  void _listenForCurrentSongIndexChanges() async {
    print("Listening for index changes");

    audioPlayer.currentIndexStream.listen((index) async {
      print("Current index changed: $index");

      final playlist = queue.value;
      if (index == null || playlist.isEmpty) {
        print("Index is null or playlist is empty.");
        return;
      }

      // Fetch the current media item
      MediaItem currentItem = playlist[index];

      Uri? newArtUri;
      // Fetch the artwork URI using the getSongArt function

      try {
        await getSongArt(
          id: int.parse(currentItem.displayDescription
              .toString()), // Assuming the item.id is the song's ID as a string
          type: ArtworkType.AUDIO,
          quality: 100,
          size: 200,
        ).then((value) {
          newArtUri = value;
          print("Current media item1: ${newArtUri}");
        });
      } catch (e) {
        debugPrint("Current media item2:$e");
      }
      debugPrint("Current media item4:${newArtUri}");
      // Update the media item with the new artUri
      if (newArtUri != null) {
        // Create a modified MediaItem with the new artUri
        debugPrint("Current media item3:${newArtUri}");
        MediaItem updatedItem = currentItem.copyWith(artUri: newArtUri);

        // Update the mediaItem stream with the modified item
        mediaItem.add(updatedItem);
        print("Updated media item with new artUri: ${newArtUri.toString()}");
      } else {
        // If no new artwork is found, add the original item
        mediaItem.add(currentItem);
        print("No new artwork found, using original item.");
      }
    });
  }

  // Broadcast the current playback state based on the received PlaybackEvent
  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[audioPlayer.processingState]!,
      playing: audioPlayer.playing,
      updatePosition: audioPlayer.position,
      bufferedPosition: audioPlayer.bufferedPosition,
      speed: audioPlayer.speed,
      queueIndex: event.currentIndex,
    ));
  }

  // Function to initialize the songs and set up the audio player
  Future<void> initSongs({required List<MediaItem> songs}) async {
    // Listen for playback events and broadcast the state
    audioPlayer.playbackEventStream.listen(_broadcastState);

    // Create a list of audio sources from the provided songs
    final audioSource = songs.map(_createAudioSource).toList();

    // Set the audio source of the audio player to the concatenation of the audio sources
    await audioPlayer
        .setAudioSource(ConcatenatingAudioSource(children: audioSource));

    // Add the songs to the queue
    queue.value.clear();
    queue.value.addAll(songs);
    queue.add(queue.value);

    // Listen for changes in the current song index
    _listenForCurrentSongIndexChanges();

    // Listen for processing state changes and skip to the next song when completed
    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) skipToNext();
    });
  }

  // Play function to start playback
  @override
  Future<void> play() => audioPlayer.play();

  // Pause function to pause playback
  @override
  Future<void> pause() => audioPlayer.pause();

  // Seek function to change the playback position
  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  // Skip to a specific item in the queue and start playback
  @override
  Future<void> skipToQueueItem(int index) async {
    await audioPlayer.seek(Duration.zero, index: index);
    play();
  }

  // Skip to the next item in the queue
  @override
  Future<void> skipToNext() => audioPlayer.seekToNext();

  // Skip to the previous item in the queue
  @override
  Future<void> skipToPrevious() => audioPlayer.seekToPrevious();
}
