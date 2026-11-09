import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:single_radio/config.dart';
import 'package:single_radio/screens/player/player_viewmodel.dart';
import 'package:single_radio/screens/player/mediacp_cover.dart';
import 'package:single_radio/screens/timer/timer_view.dart';
import 'package:single_radio/theme.dart';
import 'package:single_radio/widgets/screen.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';

/// Premium player UI for Rádio Český ráj.
/// The original PlayerViewModel and radio playback service are unchanged.
class PlayerView extends StatefulWidget {
  const PlayerView({super.key});
  static const routeName = '/';

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView>
    with SingleTickerProviderStateMixin {
  late final PlayerViewModel viewModel =
      Provider.of<PlayerViewModel>(context, listen: true);

  late final AnimationController _equalizerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void dispose() {
    _equalizerController.dispose();
    super.dispose();
  }

  Future<void> _openWebsite(String address) async {
    await launchUrl(
      Uri.parse(address),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The equalizer moves only while the radio is playing.
    if (viewModel.isPlaying && !_equalizerController.isAnimating) {
      _equalizerController.repeat();
    } else if (!viewModel.isPlaying && _equalizerController.isAnimating) {
      _equalizerController.stop();
    }

    final heroHeight =
        math.min(MediaQuery.of(context).size.width * 0.84, 320.0).toDouble();

    return Screen(
      title: Config.title,
      home: true,
      hideOverscrollIndicator: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: heroHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B3041),
                  Color(0xFF101A27),
                  Color(0xFF080C13),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.30),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x35000000),
                  blurRadius: 24,
                  offset: Offset(0, 11),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _LivePill(isPlaying: viewModel.isPlaying),
                      const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppTheme.accentColor,
                        size: 23,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFF080C13),
                        padding: const EdgeInsets.all(8),
                        child: const MediaCpCover(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NÁŠ KRAJ. NAŠE HUDBA. VÁŠ DEN.',
                        style: TextStyle(
                          color: Color(0xFFB6C5D2),
                          fontSize: 9,
                          letterSpacing: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _Equalizer(
                        animation: _equalizerController,
                        isPlaying: viewModel.isPlaying,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
            decoration: BoxDecoration(
              color: const Color(0xFF101D2C),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFF26394A)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TrackInformation(
                    artist: viewModel.artist,
                    track: viewModel.track,
                  ),
                ),
                const SizedBox(width: 12),
                _PlayButton(
                  isPlaying: viewModel.isPlaying,
                  play: viewModel.play,
                  pause: viewModel.pause,
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.volume_down_rounded,
                size: 22,
                color: Color(0xFF95A7B8),
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              const Icon(
                Icons.volume_up_rounded,
                size: 22,
                color: Color(0xFF95A7B8),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.timer_outlined,
                  label: 'Časovač',
                  onTap: () {
                    Navigator.pushNamed(context, TimerView.routeName);
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickAction(
                  icon: Icons.auto_stories_outlined,
                  label: 'Rájoviny',
                  onTap: () => _openWebsite(Config.partnerWebsite),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _QuickAction(
                  icon: Icons.language_rounded,
                  label: 'Web rádia',
                  onTap: () => _openWebsite(Config.website),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final color = isPlaying
        ? AppTheme.accentColor
        : const Color(0xFF91A2B3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.45),
                        blurRadius: 7,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPlaying ? 'PRÁVĚ VYSÍLÁME' : 'PŘIPRAVENO K POSLECHU',
            style: TextStyle(
              color: color,
              fontSize: 9,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Equalizer extends StatelessWidget {
  const _Equalizer({
    required this.animation,
    required this.isPlaying,
  });

  final Animation<double> animation;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    const baseHeights = [7.0, 11.0, 8.0, 15.0, 10.0, 13.0, 8.0, 12.0];

    return SizedBox(
      height: 23,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(baseHeights.length, (index) {
              final wave = (math.sin(
                        animation.value * 2 * math.pi + index * 0.82,
                      ) +
                      1) /
                  2;
              final barHeight = isPlaying
                  ? 5.0 + wave * 17.0
                  : baseHeights[index];

              return Container(
                width: 4,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF36C66A),
                      Color(0xFFA6E81C),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TrackInformation extends StatelessWidget {
  const _TrackInformation({
    required this.artist,
    required this.track,
  });

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
          const Text(
            'PRÁVĚ HRAJE',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 10,
              letterSpacing: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
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

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.play,
    required this.pause,
  });

  final bool isPlaying;
  final VoidCallback play;
  final VoidCallback pause;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.accentColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: Colors.white24,
          onTap: isPlaying ? pause : play,
          child: SizedBox(
            width: 70,
            height: 70,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF101A27),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF101D2C),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFF26394A)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.accentColor, size: 23),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
