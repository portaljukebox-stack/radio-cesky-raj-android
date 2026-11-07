package cz.radioceskyraj.app;

import android.app.*;
import android.content.*;
import android.media.*;
import android.os.*;
import java.io.IOException;

public class RadioService extends Service {
    public static final String ACTION_PLAY = "cz.radioceskyraj.app.PLAY";
    public static final String ACTION_STOP = "cz.radioceskyraj.app.STOP";
    public static final String ACTION_STATE = "cz.radioceskyraj.app.STATE";
    private static final String STREAM = "https://portal.juke-box.cz:2020/stream/radioceskyraj";
    private static final String CHANNEL = "radio_playback";
    private MediaPlayer player;
    private boolean playing = false;
    private boolean preparing = false;
    private AudioManager audioManager;
    private AudioFocusRequest focusRequest;

    @Override public void onCreate() {
        super.onCreate();
        NotificationChannel ch = new NotificationChannel(CHANNEL, "Přehrávání rádia", NotificationManager.IMPORTANCE_LOW);
        getSystemService(NotificationManager.class).createNotificationChannel(ch);
        audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
    }
    private Notification notification(String state) {
        Intent open = new Intent(this, MainActivity.class);
        PendingIntent openPi = PendingIntent.getActivity(this, 1, open, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        Intent stop = new Intent(this, RadioService.class).setAction(ACTION_STOP);
        PendingIntent stopPi = PendingIntent.getService(this, 2, stop, PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
        return new Notification.Builder(this, CHANNEL).setContentTitle("Rádio Český ráj")
            .setContentText(state).setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(openPi).addAction(android.R.drawable.ic_media_pause, "Zastavit", stopPi)
            .setOngoing(true).build();
    }
    private void sendState(String state) {
        Intent intent = new Intent(ACTION_STATE).setPackage(getPackageName());
        intent.putExtra("state", state);
        sendBroadcast(intent);
    }
    private void cleanup() {
        if (player != null) {
            try { player.reset(); player.release(); } catch(Exception ignored) {}
            player = null;
        }
        playing = false; preparing = false;
        if (focusRequest != null) audioManager.abandonAudioFocusRequest(focusRequest);
    }
    private void startPlayback() {
        if (playing || preparing) return;
        AudioAttributes attrs = new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build();
        focusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(attrs)
            .setOnAudioFocusChangeListener(change -> {
                if (change == AudioManager.AUDIOFOCUS_LOSS) stopPlayback();
                else if (change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT && player != null && playing) {
                    player.pause(); playing = false; sendState("Přerušeno");
                } else if (change == AudioManager.AUDIOFOCUS_GAIN && player != null && !playing && !preparing) {
                    player.start(); playing = true; sendState("Hraje živě");
                }
            }).build();
        if (audioManager.requestAudioFocus(focusRequest) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            sendState("Zvuk používá jiná aplikace"); return;
        }
        startForeground(1001, notification("Připojování…"));
        preparing = true; sendState("Připojování…");
        try {
            player = new MediaPlayer();
            player.setAudioAttributes(attrs);
            player.setDataSource(STREAM);
            player.setOnPreparedListener(mp -> {
                preparing = false; playing = true;
                mp.start();
                getSystemService(NotificationManager.class).notify(1001, notification("Hraje živě"));
                sendState("Hraje živě");
            });
            player.setOnErrorListener((mp, what, extra) -> {
                sendState("Stream se nepodařilo přehrát");
                stopPlayback(); return true;
            });
            player.prepareAsync();
        } catch (IOException | RuntimeException ex) {
            sendState("Připojení selhalo");
            stopPlayback();
        }
    }
    private void stopPlayback() {
        cleanup();
        stopForeground(STOP_FOREGROUND_REMOVE);
        sendState("Zastaveno");
        stopSelf();
    }
    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) stopPlayback();
        else startPlayback();
        return START_NOT_STICKY;
    }
    @Override public void onDestroy() { cleanup(); super.onDestroy(); }
    @Override public IBinder onBind(Intent intent) { return null; }
}
