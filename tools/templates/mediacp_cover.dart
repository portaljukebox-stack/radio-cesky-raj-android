import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:single_radio/theme.dart';

/// Public cover artwork from the *same* MediaCP widget as the radio website.
/// This does not change or restart the original streaming audio service.
class MediaCpCover extends StatefulWidget {
  const MediaCpCover({super.key});

  @override
  State<MediaCpCover> createState() => _MediaCpCoverState();
}

class _MediaCpCoverState extends State<MediaCpCover>
    with WidgetsBindingObserver {
  static const String _endpoint =
      'https://portal.juke-box.cz:2020/json/stream/radioceskyraj';
  static const String _stationLogo = 'assets/images/rcr_full_logo.png';

  Timer? _refreshTimer;
  bool _requestInProgress = false;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  /// MediaCP returns a default vinyl illustration if it cannot find artwork.
  /// Treat that generic placeholder as "no cover" and show our station logo.
  String? _validatedCover(dynamic value) {
    if (value is! String) return null;
    final url = value.trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    final path = uri.path.toLowerCase();
    if (path.contains('/defaultcover/') ||
        path.contains('black-vinyl-record') ||
        path.contains('default-cover') ||
        path.contains('placeholder') ||
        path.contains('no-cover')) {
      return null;
    }
    return url;
  }

  Future<void> _refresh() async {
    if (!mounted || _requestInProgress) return;
    _requestInProgress = true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
    try {
      final request = await client
          .getUrl(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response = await request.close().timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode != HttpStatus.ok) {
        // Network trouble should never break radio playback or hide
        // a cover that was already successfully loaded.
        return;
      }
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 8));
      final payload = jsonDecode(body);
      if (payload is! Map<String, dynamic>) return;
      final next = payload['status'] == true
          ? _validatedCover(payload['coverart'])
          : null;

      if (!mounted || next == _coverUrl) return;
      setState(() => _coverUrl = next);
    } on SocketException {
      // The station logo remains available offline.
    } on TimeoutException {
      // Do not interrupt the music if the artwork endpoint is slow.
    } on FormatException {
      // Ignore malformed metadata and show existing brand artwork.
    } catch (_) {
      // Image and JSON availability must never affect music playback.
    } finally {
      client.close(force: true);
      _requestInProgress = false;
    }
  }

  Widget _logo() => Image.asset(
        _stationLogo,
        key: const ValueKey('rcr-station-logo'),
        fit: BoxFit.contain,
        width: double.infinity,
        filterQuality: FilterQuality.high,
      );

  @override
  Widget build(BuildContext context) {
    final cover = _coverUrl;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: cover == null
          ? _logo()
          : Image.network(
              cover,
              key: ValueKey('mediacp:$cover'),
              width: double.infinity,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _logo();
              },
              errorBuilder: (context, error, stackTrace) => _logo(),
            ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
