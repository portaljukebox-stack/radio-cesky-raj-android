#!/usr/bin/env python3
"""Extend the pinned radio_player Android service for a private Android Auto build.

Patch the exact dependency source in the CI pub cache; refuse unknown versions.
No production MediaCP or station settings are changed.
"""
from pathlib import Path

root = Path.home() / '.pub-cache/hosted/pub.dev/radio_player-1.2.1/android/src/main'
service = root / 'kotlin/com/cheebeez/radio_player/RadioPlayerService.kt'
manifest = Path('android/app/src/main/AndroidManifest.xml')
car_xml = Path('android/app/src/main/res/xml/automotive_app_desc.xml')

def replace_once(source, old, new):
    if source.count(old) != 1:
        raise SystemExit('STOP: pinned radio_player source differs: ' + old[:75])
    return source.replace(old, new, 1)

s = service.read_text(encoding='utf-8')
s = replace_once(s,
    'import android.support.v4.media.session.MediaSessionCompat',
    '''import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import androidx.media.MediaBrowserServiceCompat
import android.os.Bundle''')
s = replace_once(s, 'class RadioPlayerService : Service(), Player.Listener {',
    'class RadioPlayerService : MediaBrowserServiceCompat(), Player.Listener {')
s = replace_once(s, 'parseUrls(streamUrl).map { MediaItem.fromUri(it) }',
    '''parseUrls(streamUrl).map { url -> MediaItem.Builder()
                        .setUri(url)
                        .setMediaMetadata(com.google.android.exoplayer2.MediaMetadata.Builder()
                            .setTitle(streamTitle).setArtist("Rádio Český ráj").build())
                        .build() }''')
s = replace_once(s,
    '''    override fun onBind(intent: Intent?): IBinder? {
        return localBinder
    }''',
    '''    override fun onCreate() {
        super.onCreate()
        context = applicationContext
        player.setRepeatMode(Player.REPEAT_MODE_ONE)
        player.addListener(this)
        // A car can connect before Flutter or its Activity has started.
        setMediaItem("Rádio Český ráj", "https://portal.juke-box.cz:2020/stream/radioceskyraj")
    }

    override fun onGetRoot(clientPackageName: String, clientUid: Int, rootHints: Bundle?): BrowserRoot? {
        return BrowserRoot("rcr_root", null)
    }

    override fun onLoadChildren(parentId: String, result: Result<List<MediaBrowserCompat.MediaItem>>) {
        if (parentId != "rcr_root") {
            result.sendResult(emptyList())
            return
        }
        val item = MediaDescriptionCompat.Builder()
            .setMediaId("rcr_stream")
            .setTitle("Rádio Český ráj")
            .setSubtitle("Živé vysílání")
            .build()
        result.sendResult(listOf(MediaBrowserCompat.MediaItem(item, MediaBrowserCompat.MediaItem.FLAG_PLAYABLE)))
    }

    override fun onBind(intent: Intent?): IBinder? {
        return if (intent?.action == "android.media.browse.MediaBrowserService")
            super.onBind(intent) else localBinder
    }''')
s = replace_once(s,
    '''    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        player.setRepeatMode(Player.REPEAT_MODE_ONE)
        player.addListener(this)

        return START_NOT_STICKY
    }''',
    '''    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_NOT_STICKY
    }''')
s = replace_once(s,
    '''            mediaSessionConnector.setPlayer(player)
        }''',
    '''            mediaSessionConnector.setPlayer(player)
            // Route car controls to the same ExoPlayer instance used by Flutter.
            it.setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() { play() }
                override fun onPause() { pause() }
                override fun onStop() { stop() }
                override fun onPlayFromMediaId(mediaId: String?, extras: Bundle?) {
                    if (mediaId == "rcr_stream") play()
                }
            })
            setSessionToken(it.sessionToken)
        }''')

m = manifest.read_text(encoding='utf-8')
m = replace_once(m, 'android:exported="false"\n            android:foregroundServiceType="mediaPlayback"',
    '''android:exported="true"
            android:foregroundServiceType="mediaPlayback"''')
m = replace_once(m,
    '''android:foregroundServiceType="mediaPlayback" />''',
    '''android:foregroundServiceType="mediaPlayback">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>''')
m = replace_once(m, '    </application>',
    '''        <meta-data android:name="com.google.android.gms.car.application"
            android:resource="@xml/automotive_app_desc" />
    </application>''')
car_xml.parent.mkdir(parents=True, exist_ok=True)
car_xml.write_text('''<?xml version="1.0" encoding="utf-8"?>
<automotiveApp xmlns:android="http://schemas.android.com/apk/res/android">
    <uses name="media" />
</automotiveApp>
''', encoding='utf-8')
service.write_text(s, encoding='utf-8')
manifest.write_text(m, encoding='utf-8')
print('Android Auto browser, browse item, shared session and transport controls added')
