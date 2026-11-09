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

/// Refined, responsive live-radio screen.
/// The original PlayerViewModel, stream service and timer remain untouched.
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
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void dispose() {
    _equalizerController.dispose();
    super.dispose();
  }

  Future<void> _openWebsite(String address) async {
    final uri = Uri.tryParse(address);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.isPlaying && !_equalizerController.isAnimating) {
      _equalizerController.repeat();
    } else if (!viewModel.isPlaying && _equalizerController.isAnimating) {
      _equalizerController.stop();
    }

    final media = MediaQuery.of(context);
    final compact = media.size.height < 760;
    final artworkSize = math
        .min(media.size.width - 92, compact ? 226.0 : 276.0)
        .toDouble();
    final availableHeight = media.size.height -
        media.padding.top -
        media.padding.bottom -
        kToolbarHeight -
        38;
    final targetHeight = math.max(560.0, availableHeight).toDouble();

    return Screen(
      title: Config.title,
      home: true,
      hideOverscrollIndicator: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bodyHeight = constraints.maxHeight.isFinite
              ? math.max(targetHeight, constraints.maxHeight).toDouble()
              : targetHeight;

          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: bodyHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BroadcastHeader(
                  isPlaying: viewModel.isPlaying,
                  animation: _equalizerController,
                ),
                Center(
                  child: _ArtworkCard(size: artworkSize),
                ),
                _NowPlayingCard(
                  artist: viewModel.artist,
                  track: viewModel.track,
                  isPlaying: viewModel.isPlaying,
                  play: viewModel.play,
                  pause: viewModel.pause,
                ),
                _VolumeControl(
                  volume: viewModel.volume,
                  onChanged: viewModel.setVolume,
                ),
                _QuickActions(
                  onTimer: () {
                    Navigator.pushNamed(context, TimerView.routeName);
                  },
                  onPartner: () => _openWebsite(Config.partnerWebsite),
                  onWebsite: () => _openWebsite(Config.website),
                ),
                const _BrandFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BroadcastHeader extends StatelessWidget {
  const _BroadcastHeader({
    required this.isPlaying,
    required this.animation,
  });

  final bool isPlaying;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final active = isPlaying ? AppTheme.accentColor : const Color(0xFF8FA2B4);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF172A3A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: active.withOpacity(0.34)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active,
                  shape: BoxShape.circle,
                  boxShadow: isPlaying
                      ? [BoxShadow(color: active.withOpacity(0.6), blurRadius: 9)]
                      : null,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                isPlaying ? 'ŽIVĚ Z ČESKÉHO RÁJE' : 'PŘIPRAVENO K POSLECHU',
                style: TextStyle(
                  color: active,
                  fontSize: 10,
                  letterSpacing: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _Equalizer(animation: animation, isPlaying: isPlaying, height: 27),
      ],
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF28465A),
            Color(0xFF132536),
            Color(0xFF080E17),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.27),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02060B).withOpacity(0.55),
            blurRadius: 28,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.07),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: const MediaCpCover(),
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  const _NowPlayingCard({
    required this.artist,
    required this.track,
    required this.isPlaying,
    required this.play,
    required this.pause,
  });

  final String artist;
  final String track;
  final bool isPlaying;
  final VoidCallback play;
  final VoidCallback pause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 15, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172A3A), Color(0xFF101C2B)],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFF2A4052)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.graphic_eq_rounded,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'PRÁVĚ HRAJE',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 10,
                        letterSpacing: 1.55,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 25,
                  child: TextScroll(
                    artist,
                    numberOfReps: Config.textScrolling ? null : 0,
                    velocity: const Velocity(pixelsPerSecond: Offset(27, 0)),
                    delayBefore: const Duration(seconds: 1),
                    pauseBetween: const Duration(seconds: 2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 22,
                  child: TextScroll(
                    track,
                    numberOfReps: Config.textScrolling ? null : 0,
                    velocity: const Velocity(pixelsPerSecond: Offset(32, 0)),
                    delayBefore: const Duration(seconds: 1),
                    pauseBetween: const Duration(seconds: 2),
                    style: const TextStyle(
                      color: Color(0xFFB6C6D5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PlayButton(
            isPlaying: isPlaying,
            play: play,
            pause: pause,
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
            color: AppTheme.accentColor.withOpacity(0.28),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.accentColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
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
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.volume,
    required this.onChanged,
  });

  final double volume;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeVolume = volume.clamp(0.0, 100.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF101D2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24394B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.volume_down_rounded,
            size: 21,
            color: Color(0xFF9FB0C0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppTheme.accentColor,
                inactiveTrackColor: const Color(0xFF2A3B4C),
                thumbColor: AppTheme.accentColor,
              ),
              child: Slider(
                value: safeVolume,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.volume_up_rounded,
            size: 21,
            color: Color(0xFF9FB0C0),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onTimer,
    required this.onPartner,
    required this.onWebsite,
  });

  final VoidCallback onTimer;
  final VoidCallback onPartner;
  final VoidCallback onWebsite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.timer_outlined,
            label: 'Časovač',
            onTap: onTimer,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.auto_stories_rounded,
            label: 'Rájoviny',
            onTap: onPartner,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            icon: Icons.language_rounded,
            label: 'Web rádia',
            onTap: onWebsite,
          ),
        ),
      ],
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: Ink(
          height: 78,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF172A3A), Color(0xFF101C2B)],
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFF2A4052)),
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

class _Equalizer extends StatelessWidget {
  const _Equalizer({
    required this.animation,
    required this.isPlaying,
    this.height = 24,
  });

  final Animation<double> animation;
  final bool isPlaying;
  final double height;

  @override
  Widget build(BuildContext context) {
    const baseHeights = [7.0, 11.0, 8.0, 16.0, 10.0, 14.0, 8.0, 12.0];
    return SizedBox(
      height: height,
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
              final barHeight =
                  isPlaying ? 5.0 + wave * (height - 5.0) : baseHeights[index];
              return Container(
                width: 4,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF24BFA0), Color(0xFFA6E81C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.20),
                      blurRadius: 5,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'NÁŠ KRAJ. NAŠE HUDBA. VÁŠ DEN.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9FB0C0),
              fontSize: 9,
              letterSpacing: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}
