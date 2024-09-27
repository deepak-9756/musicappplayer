import 'package:audio_service/audio_service.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // Import necessary packages
import 'package:musicappplayer/audiohandler..dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:on_audio_query/on_audio_query.dart'; // For SVG images

class MusicPlayerScreen extends StatefulWidget with WidgetsBindingObserver {
  final SongHandler songHandler; // Correctly name the parameter

  MusicPlayerScreen({super.key, required this.songHandler});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    // Dispose of your songHandler if necessary
    //widget.songHandler.audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(),
        ),
        StreamBuilder<MediaItem?>(
          stream: widget.songHandler.mediaItem.stream,
          builder: (BuildContext context, AsyncSnapshot<MediaItem?> snapshot) {
            final Duration totalDuration = snapshot.data!.duration!;
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back)),
                      Text(
                        "Player",
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (snapshot.data != null)
                          QueryArtworkWidget(
                            artworkClipBehavior: Clip.antiAlias,
                            artworkFit: BoxFit.cover,
                            id: int.parse(
                                snapshot.data!.displayDescription.toString()),
                            type: ArtworkType.AUDIO,
                            artworkBorder: BorderRadius.circular(50),
                            artworkWidth:
                                MediaQuery.sizeOf(context).width * 0.7,
                            artworkHeight:
                                MediaQuery.sizeOf(context).width * 0.7,
                          ),
                        SizedBox(
                            height: MediaQuery.sizeOf(context).height * .06),
                        SizedBox(
                          width: 200,
                          child: Text(
                            snapshot.data!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        StreamBuilder<Duration?>(
                          initialData: null,
                          stream: AudioService.position,
                          builder: (BuildContext context,
                              AsyncSnapshot<Duration?> snapshot) {
                            Duration? position = snapshot.data;
                            return Column(
                              children: [
                                // if (snapshot.data != null &&
                                //     widget.songHandler.audioPlayer.duration !=
                                //         null)
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 70,
                                    child: ProgressBar(
                                      // Set the progress to the current position or zero if null
                                      progress: position ?? Duration.zero,
                                      // Set the total duration of the song
                                      total: totalDuration,
                                      // Callback for seeking when the user interacts with the progress bar
                                      onSeek: (position) {
                                        widget.songHandler.seek(position);
                                      },
                                      // Customize the appearance of the progress bar
                                      barHeight: 5,
                                      thumbRadius: 2.5,
                                      thumbGlowRadius: 5,
                                      timeLabelLocation:
                                          TimeLabelLocation.below,
                                      timeLabelPadding: 10,
                                    )),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(
                                onPressed: () async {
                                  await widget.songHandler.audioPlayer
                                      .seekToPrevious();
                                },
                                icon: const Icon(
                                  size: 40,
                                  Icons.arrow_back_ios,
                                  color: Color(0xFF028B51),
                                )),
                            const SizedBox(width: 30),
                            StreamBuilder<PlayerState>(
                              stream: widget
                                  .songHandler.audioPlayer.playerStateStream,
                              builder: (context, snapshot) {
                                final playerState = snapshot.data;
                                final playing = playerState?.playing ?? false;

                                return GestureDetector(
                                    onTap: () async {
                                      if (playing) {
                                        await widget.songHandler.audioPlayer
                                            .pause();
                                      } else {
                                        await widget.songHandler.audioPlayer
                                            .play();
                                      }
                                    },
                                    child: playing
                                        ? Icon(Icons.pause)
                                        : Icon(Icons.play_arrow));
                              },
                            ),
                            const SizedBox(width: 30),
                            IconButton(
                                onPressed: () async {
                                  await widget.songHandler.audioPlayer
                                      .seekToNext();
                                },
                                icon: const Icon(
                                  size: 40,
                                  Icons.arrow_forward_ios,
                                  color: Color(0xFF028B51),
                                )),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ]),
    );
  }
}
