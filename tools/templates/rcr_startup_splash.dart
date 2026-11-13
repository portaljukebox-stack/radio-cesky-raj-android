import 'dart:async';
import 'package:flutter/material.dart';

/// Branded screen displayed above the existing player only at app startup.
/// The underlying view remains mounted; radio playback is never restarted.
class RcrStartupSplash extends StatefulWidget {
  const RcrStartupSplash({super.key, required this.child});

  final Widget child;

  @override
  State<RcrStartupSplash> createState() => _RcrStartupSplashState();
}

class _RcrStartupSplashState extends State<RcrStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _hold;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
    _hold = Timer(const Duration(milliseconds: 1550), () async {
      if (!mounted) return;
      await _fade.reverse();
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (_visible)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fade,
                child: ColoredBox(
                  color: const Color(0xFF061329),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Image.asset(
                        'assets/images/rcr_premium_splash.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(color: Color(0xFF061329));
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
