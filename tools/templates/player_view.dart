import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:single_radio/config.dart';
import 'package:single_radio/screens/player/player_viewmodel.dart';
import 'package:single_radio/theme.dart';
import 'package:single_radio/widgets/screen.dart';
import 'package:text_scroll/text_scroll.dart';

/// Redesigned layout of the ORIGINAL player. The radio engine, timer,
/// streaming and external navigation remain unchanged.
class PlayerView extends StatefulWidget {
  const PlayerView({super.key});
  static const routeName = '/';

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late final viewModel = Provider.of<PlayerViewModel>(context, listen: true);

  @override
  Widget build(BuildContext context) {
    return Screen(
      title: Config.title,
      home: true,
      hideOverscrollIndicator: true,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final maxHeight = constraints.maxHeight;
                final heroHeight = math.max(
                  100.0,
                  math.min(315.0,
                    math.min(width * 0.79, maxHeight - 38.0)),
                );

                return Center(
                  child: Container(
                    width: double.infinity,
                    height: heroHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF080C13),
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.23),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x35000000),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 19),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text('ŽIVÉ VYSÍLÁNÍ',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Expanded(
                            child: Center(
                              child: Image.asset(
                                'assets/images/rcr_full_logo.png',
                                width: double.infinity,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF101D2C),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFF26394A)),
            ),
            child: Row(
              children: [
                if (viewModel.artwork != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      height: 56,
                      width: 56,
                      child: viewModel.artwork!,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _TrackInformation(
                    artist: viewModel.artist,
                    track: viewModel.track,
                  ),
                ),
                const SizedBox(width: 10),
                _ControlButton(
                  isPlaying: viewModel.isPlaying,
                  play: viewModel.play,
                  pause: viewModel.pause,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.volume_down_rounded,
                size: 22, color: Color(0xFF95A7B8)),
              const SizedBox(width: 9),
              Expanded(
                child: Slider(
                  value: viewModel.volume.clamp(0.0, 100.0).toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: viewModel.volume.round().toString(),
                  onChanged: viewModel.setVolume,
                ),
              ),
              const SizedBox(width: 9),
              const Icon(Icons.volume_up_rounded,
                size: 22, color: Color(0xFF95A7B8)),
            ],
          ),
          const SizedBox(height: 29),
        ],
      ),
    );
  }
}

class _TrackInformation extends StatelessWidget {
  const _TrackInformation({required this.artist, required this.track});
  final String artist;
  final String track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRÁVĚ HRAJE',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 25,
            child: TextScroll(
              artist,
              numberOfReps: Config.textScrolling ? null : 0,
              velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
              delayBefore: const Duration(seconds: 1),
              pauseBetween: const Duration(seconds: 2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 21,
            child: TextScroll(
              track,
              numberOfReps: Config.textScrolling ? null : 0,
              velocity: const Velocity(pixelsPerSecond: Offset(35, 0)),
              delayBefore: const Duration(seconds: 1),
              pauseBetween: const Duration(seconds: 2),
              style: const TextStyle(
                color: Color(0xFFB7C6D5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.isPlaying,
    required this.play,
    required this.pause,
  });
  final bool isPlaying;
  final VoidCallback play;
  final VoidCallback pause;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.accentColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: Colors.white24,
        onTap: isPlaying ? pause : play,
        child: SizedBox(
          width: 68,
          height: 68,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: const Color(0xFF101A27),
            size: 39,
          ),
        ),
      ),
    );
  }
}
