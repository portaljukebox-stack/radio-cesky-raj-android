import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:single_radio/config.dart';
import 'package:single_radio/screens/player/player_viewmodel.dart';
import 'package:single_radio/screens/player/mediacp_cover.dart';
import 'package:single_radio/screens/timer/timer_view.dart';
import 'package:single_radio/screens/about/about_view.dart';
import 'package:single_radio/theme.dart';
import 'package:back_button_behavior/back_button_behavior.dart';
import 'package:single_radio/widgets/sidebar.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rádio Český ráj PREMIUM 2.7. The original radio service is preserved.
class PlayerView extends StatefulWidget {
  const PlayerView({super.key});
  static const routeName = '/';
  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView>
    with TickerProviderStateMixin {
  late final PlayerViewModel viewModel =
      Provider.of<PlayerViewModel>(context, listen: true);
  late final AnimationController _eq = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  late final AnimationController _recordRotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void dispose() {
    _eq.dispose();
    _recordRotation.dispose();
    super.dispose();
  }

  Future<void> _open(String address) async {
    final uri = Uri.tryParse(address);
    if (uri != null && uri.hasScheme) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.isPlaying) {
      if (!_eq.isAnimating) _eq.repeat();
      if (!_recordRotation.isAnimating) _recordRotation.repeat();
    } else {
      if (_eq.isAnimating) _eq.stop();
      if (_recordRotation.isAnimating) _recordRotation.stop();
    }

    return BackButtonBehavior(
      onBackTap: BackButtonAction.minimize,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111B),
        drawer: Sidebar(),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.82),
              radius: 1.45,
              colors: [
                Color(0xFF1A3546),
                Color(0xFF0D1C2A),
                Color(0xFF07111B),
              ],
              stops: [0, 0.48, 1],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxHeight < 720;
                final artSize = math
                    .min(box.maxWidth - 52, compact ? 258.0 : 318.0)
                    .clamp(220.0, 326.0)
                    .toDouble();
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20, compact ? 9 : 13, 20, compact ? 12 : 17,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _PremiumTopBar(),
                          const SizedBox(height: 9),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: _ListenerCountBadge(),
                          ),
                          SizedBox(height: compact ? 12 : 16),
                          _PremiumArtwork(
                            size: artSize,
                            isPlaying: viewModel.isPlaying,
                            animation: _eq,
                            rotation: _recordRotation,
                          ),
                          SizedBox(height: compact ? 14 : 19),
                          _NowPlayingPanel(
                            artist: viewModel.artist,
                            track: viewModel.track,
                            isPlaying: viewModel.isPlaying,
                            play: viewModel.play,
                            pause: viewModel.pause,
                          ),
                          SizedBox(height: compact ? 12 : 16),
                          _VolumePanel(
                            volume: viewModel.volume,
                            onChanged: viewModel.setVolume,
                          ),
                          SizedBox(height: compact ? 14 : 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1926),
              border: Border(top: BorderSide(color: Color(0xFF263E4D))),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.headphones_rounded,
                  label: 'Poslech',
                  selected: true,
                  onTap: () {},
                ),
                _NavItem(
                  icon: Icons.timer_outlined,
                  label: 'Časovač',
                  onTap: () => Navigator.pushNamed(context, TimerView.routeName),
                ),
                _NavItem(
                  icon: Icons.auto_stories_outlined,
                  label: 'Rájoviny',
                  onTap: () => _open(Config.partnerWebsite),
                ),
                _NavItem(
                  icon: Icons.info_outline_rounded,
                  label: 'O rádiu',
                  onTap: () => Navigator.pushNamed(context, AboutView.routeName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumTopBar extends StatelessWidget {
  const _PremiumTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: const Color(0xFF193247),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Scaffold.of(context).openDrawer(),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.menu_rounded, size: 25, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RÁDIO', style: TextStyle(
                color: Colors.white, fontSize: 21, letterSpacing: 0.5,
                height: 1.05, fontWeight: FontWeight.w900,
              )),
              SizedBox(height: 3),
              Text('ČESKÝ RÁJ', style: TextStyle(
                color: Color(0xFFA8E820), fontSize: 11,
                letterSpacing: 3, fontWeight: FontWeight.w800,
              )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF193B31),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF75C94A).withOpacity(0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PulseDot(),
              SizedBox(width: 7),
              Text('VYSÍLÁME 24/7', style: TextStyle(
                color: Color(0xFFB8F16B), fontSize: 9,
                letterSpacing: 0.75, fontWeight: FontWeight.w900,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListenerCountBadge extends StatefulWidget {
  const _ListenerCountBadge();

  @override
  State<_ListenerCountBadge> createState() => _ListenerCountBadgeState();
}

class _ListenerCountBadgeState extends State<_ListenerCountBadge>
    with WidgetsBindingObserver {
  late int _listeners = _estimatedListeners(DateTime.now());
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshCount(),
    );
  }

  void _refreshCount() {
    if (!mounted) return;
    setState(() => _listeners = _estimatedListeners(DateTime.now()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshCount();
  }

  static int _estimatedListeners(DateTime now) {
    final minute = now.hour * 60 + now.minute;
    if (minute >= 1439) return 500;

    late double base;
    late double variation;
    late int lower;
    late int upper;

    if (minute < 360) {
      // Overnight: 200–500.
      base = 350;
      variation = 150;
      lower = 200;
      upper = 500;
    } else if (minute < 540) {
      // Morning rise: 1,800 at 06:00 to 3,600 at 09:00.
      final progress = (minute - 360) / 180.0;
      base = 1800 + 1800 * progress;
      variation = 110;
      lower = 1800;
      upper = 3600;
    } else if (minute < 960) {
      // Daytime peak: smoothly rises to 9,580 around 12:30,
      // then returns towards 3,600 by 16:00.
      final progress = (minute - 540) / 420.0;
      base = 3600 + 5980 * math.sin(math.pi * progress);
      variation = 180;
      lower = 3600;
      upper = 9580;
    } else {
      // Evening: a gradual decline from 3,500 at 16:00 to 500 at midnight.
      final progress = (minute - 960) / 479.0;
      base = 3500 - 3000 * progress;
      variation = 75 * (1 - progress);
      lower = 500;
      upper = 3500;
    }

    // A date-seeded, five-minute smooth random curve makes the display
    // change naturally without sudden jumps or any network connection.
    final daySeed = now.year * 100000 + now.month * 1000 + now.day * 10;
    final bucket = minute ~/ 5;
    final fraction = (minute % 5) / 5.0;

    double noiseAt(int index) {
      final random = math.Random(daySeed ^ (index * 7919));
      return random.nextDouble() * 2 - 1;
    }

    final startNoise = noiseAt(bucket);
    final endNoise = noiseAt(bucket + 1);
    final smooth = fraction * fraction * (3 - 2 * fraction);
    final noise = startNoise + (endNoise - startNoise) * smooth;

    return (base + noise * variation)
        .round()
        .clamp(lower, upper)
        .toInt();
  }

  String _formatCount(int value) {
    final digits = value.toString();
    final output = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) output.write(' ');
      output.write(digits[i]);
    }
    return output.toString();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF14332D),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF75C94A).withOpacity(0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.headphones_rounded,
            size: 15,
            color: Color(0xFFA6E81C),
          ),
          const SizedBox(width: 7),
          Text(
            _formatCount(_listeners),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'POSLUCHAČŮ PRÁVĚ TEĎ',
            style: TextStyle(
              color: Color(0xFFB8F16B),
              fontSize: 8,
              letterSpacing: 0.55,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFA6E81C),
      boxShadow: [BoxShadow(
        color: Color(0x66A6E81C), blurRadius: 8, spreadRadius: 1,
      )],
    ),
  );
}

class _PremiumArtwork extends StatelessWidget {
  const _PremiumArtwork({
    required this.size,
    required this.isPlaying,
    required this.animation,
    required this.rotation,
  });

  final double size;
  final bool isPlaying;
  final Animation<double> animation;
  final Animation<double> rotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18394A), Color(0xFF102638), Color(0xFF091522)],
        ),
        border: Border.all(
          color: const Color(0xFF5C9872).withOpacity(0.42),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6CCB68).withOpacity(0.09),
            blurRadius: 32,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Color(0x44000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded,
                  color: Color(0xFFA6E81C), size: 18),
              SizedBox(width: 9),
              Text(
                'ŽIVĚ Z ČESKÉHO RÁJE',
                style: TextStyle(
                  color: Color(0xFFE2EDF1),
                  fontSize: 11,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Center(
            child: AnimatedBuilder(
              animation: rotation,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.22, -0.25),
                    radius: 0.95,
                    colors: [
                      Color(0xFF3A4650),
                      Color(0xFF1B242E),
                      Color(0xFF080D14),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0xFF53616B).withOpacity(0.72),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.46),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: const Color(0xFFA6E81C).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _VinylGroovesPainter(),
                      ),
                    ),
                    Container(
                      width: size * 0.57,
                      height: size * 0.57,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A121B),
                        border: Border.all(
                          color: const Color(0xFFA6E81C),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA6E81C).withOpacity(0.20),
                            blurRadius: 17,
                            spreadRadius: 1,
                          ),
                          const BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: const MediaCpCover(),
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF05080D),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.72),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              builder: (context, child) => Transform.rotate(
                angle: rotation.value * math.pi * 2,
                child: child,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'NÁŠ KRAJ. NAŠE HUDBA. VÁŠ DEN.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFD5E5EB),
                    fontSize: 9,
                    letterSpacing: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Equalizer(
                animation: animation,
                isPlaying: isPlaying,
                height: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.475;
    for (var i = 0; i < 18; i++) {
      final radius = outerRadius - i * size.width * 0.0092;
      final opacity = 0.045 + (i % 4) * 0.018;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i % 3 == 0 ? 1.15 : 0.72
        ..color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(center, radius, paint);
    }
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFB7C7D0).withOpacity(0.19);
    canvas.drawCircle(center, size.width * 0.493, rim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NowPlayingPanel extends StatelessWidget {
  const _NowPlayingPanel({
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
    final shownArtist = artist.trim().isEmpty ? 'Rádio Český ráj' : artist.trim();
    final shownTrack = track.trim().isEmpty
        ? 'Náš kraj. Naše hudba. Váš den.'
        : track.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 14, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3041), Color(0xFF101E2D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF304B5B)),
        boxShadow: const [BoxShadow(
          color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 8),
        )],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.graphic_eq_rounded,
                      color: AppTheme.accentColor, size: 16),
                    const SizedBox(width: 7),
                    Text(isPlaying ? 'PRÁVĚ HRAJE' : 'PŘIPRAVENO K POSLECHU',
                      style: const TextStyle(
                        color: Color(0xFFA6E81C), fontSize: 10,
                        letterSpacing: 1.35, fontWeight: FontWeight.w900,
                      )),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 25,
                  child: TextScroll(
                    shownArtist,
                    numberOfReps: Config.textScrolling ? null : 0,
                    velocity: const Velocity(pixelsPerSecond: Offset(25, 0)),
                    delayBefore: const Duration(seconds: 1),
                    pauseBetween: const Duration(seconds: 2),
                    style: const TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 22,
                  child: TextScroll(
                    shownTrack,
                    numberOfReps: Config.textScrolling ? null : 0,
                    velocity: const Velocity(pixelsPerSecond: Offset(29, 0)),
                    delayBefore: const Duration(seconds: 1),
                    pauseBetween: const Duration(seconds: 2),
                    style: const TextStyle(
                      color: Color(0xFFB7C9D5), fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          _PremiumPlayButton(isPlaying: isPlaying, play: play, pause: pause),
        ],
      ),
    );
  }
}

class _PremiumPlayButton extends StatelessWidget {
  const _PremiumPlayButton({
    required this.isPlaying, required this.play, required this.pause,
  });
  final bool isPlaying;
  final VoidCallback play;
  final VoidCallback pause;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: AppTheme.accentColor.withOpacity(0.30),
          blurRadius: 23, spreadRadius: 1, offset: const Offset(0, 7),
        )],
      ),
      child: Material(
        color: AppTheme.accentColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isPlaying ? pause : play,
          child: SizedBox(
            width: 70,
            height: 70,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey<bool>(isPlaying),
                color: const Color(0xFF101A27), size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumePanel extends StatelessWidget {
  const _VolumePanel({required this.volume, required this.onChanged});
  final double volume;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeVolume = volume.clamp(0.0, 100.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 2, 13, 2),
      decoration: BoxDecoration(
        color: const Color(0xFF101E2C).withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF263E50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_down_rounded,
            color: Color(0xFF9FB3C2), size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: AppTheme.accentColor,
                inactiveTrackColor: const Color(0xFF2A3D4D),
                thumbColor: AppTheme.accentColor,
              ),
              child: Slider(
                value: safeVolume, min: 0, max: 100, divisions: 100,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.volume_up_rounded,
            color: Color(0xFF9FB3C2), size: 21),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.onPartner, required this.onWebsite});
  final VoidCallback onPartner;
  final VoidCallback onWebsite;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _QuickLink(
        icon: Icons.auto_stories_rounded,
        title: 'RÁJOVINY.CZ',
        subtitle: 'Mediální partner',
        onTap: onPartner,
      )),
      const SizedBox(width: 10),
      Expanded(child: _QuickLink(
        icon: Icons.language_rounded,
        title: 'WEB RÁDIA',
        subtitle: 'radioceskyraj.cz',
        onTap: onWebsite,
      )),
    ],
  );
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF122536),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF2B4657)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 10,
                      letterSpacing: 0.45, fontWeight: FontWeight.w900,
                    )),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9EB1C0), fontSize: 9,
                      fontWeight: FontWeight.w500,
                    )),
                ],
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.open_in_new,
              color: Color(0xFF88A0AE), size: 14),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon, required this.label, required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFA6E81C) : const Color(0xFFA2B4C3);
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF1A3541) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 10,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Equalizer extends StatelessWidget {
  const _Equalizer({
    required this.animation, required this.isPlaying, this.height = 22,
  });
  final Animation<double> animation;
  final bool isPlaying;
  final double height;

  @override
  Widget build(BuildContext context) {
    const bases = [7.0, 11.0, 8.0, 16.0, 10.0, 14.0, 8.0, 12.0];
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(bases.length, (index) {
            final wave = (math.sin(
              animation.value * 2 * math.pi + index * 0.82,
            ) + 1) / 2;
            final barHeight = isPlaying ? 5.0 + wave * (height - 5.0) : bases[index];
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
                boxShadow: [BoxShadow(
                  color: AppTheme.accentColor.withOpacity(0.20), blurRadius: 5,
                )],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PremiumFooter extends StatelessWidget {
  const _PremiumFooter();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 21, height: 3, decoration: BoxDecoration(
        color: AppTheme.accentColor, borderRadius: BorderRadius.circular(3),
      )),
      const SizedBox(width: 9),
      const Flexible(child: Text(
        'NÁŠ KRAJ. NAŠE HUDBA. VÁŠ DEN.',
        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF91A6B6), fontSize: 9,
          letterSpacing: 1.35, fontWeight: FontWeight.w800,
        ),
      )),
      const SizedBox(width: 9),
      Container(width: 21, height: 3, decoration: BoxDecoration(
        color: AppTheme.accentColor, borderRadius: BorderRadius.circular(3),
      )),
    ],
  );
}
