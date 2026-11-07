package cz.radioceskyraj.app;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import android.net.Uri;

public class MainActivity extends Activity {
    private final int bg = Color.rgb(16,26,39);
    private final int green = Color.rgb(174,239,24);
    private TextView status;
    private Button play;
    private boolean playing = false;
    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) {
            String state = intent.getStringExtra("state");
            if (state == null) return;
            status.setText(state);
            playing = state.equals("Hraje živě") || state.equals("Připojování…");
            play.setText(playing ? "■   ZASTAVIT VYSÍLÁNÍ" : "▶   PŘEHRÁT ŽIVĚ");
        }
    };
    private GradientDrawable shape(int color, int radius) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color); d.setCornerRadius(radius);
        return d;
    }
    private TextView text(String value, int size, int color, boolean bold) {
        TextView t = new TextView(this); t.setText(value); t.setTextColor(color);
        t.setTextSize(size); t.setGravity(Gravity.CENTER);
        if (bold) t.setTypeface(null, 1);
        return t;
    }
    private int dp(int n) { return (int)(getResources().getDisplayMetrics().density*n); }
    private void open(String url) { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setStatusBarColor(bg); getWindow().setNavigationBarColor(bg);
        ScrollView scroll = new ScrollView(this); scroll.setFillViewport(true); scroll.setBackgroundColor(bg);
        LinearLayout root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(24),dp(34),dp(24),dp(30)); root.setGravity(Gravity.CENTER_HORIZONTAL);
        scroll.addView(root); setContentView(scroll);
        TextView name = text("RÁDIO ČESKÝ RÁJ", 25, Color.WHITE, true);
        root.addView(name, new LinearLayout.LayoutParams(-1,dp(54)));
        TextView tagline = text("PŘÍBĚHY A HUDBA NAŠEHO KRAJE", 13, green, true);
        root.addView(tagline, new LinearLayout.LayoutParams(-1,dp(36)));
        ImageView icon = new ImageView(this); icon.setImageResource(R.drawable.radio_icon_exact);
        LinearLayout.LayoutParams imgp = new LinearLayout.LayoutParams(dp(220),dp(220));
        imgp.topMargin=dp(22);imgp.bottomMargin=dp(22);root.addView(icon,imgp);
        TextView live = text("●   ŽIVÉ VYSÍLÁNÍ", 15, green, true);
        root.addView(live, new LinearLayout.LayoutParams(-1,dp(38)));
        status = text("Připraveno k přehrávání", 16, Color.WHITE, false);
        root.addView(status, new LinearLayout.LayoutParams(-1,dp(50)));
        play = new Button(this); play.setAllCaps(false);
        play.setText("▶   PŘEHRÁT ŽIVĚ"); play.setTextColor(bg); play.setTextSize(17);
        play.setTypeface(null,1);play.setBackground(shape(green,dp(18)));
        LinearLayout.LayoutParams bp = new LinearLayout.LayoutParams(-1,dp(68));bp.topMargin=dp(18);
        root.addView(play,bp);
        play.setOnClickListener(v -> {
            Intent i = new Intent(this,RadioService.class);
            i.setAction(playing ? RadioService.ACTION_STOP : RadioService.ACTION_PLAY);
            if (playing) startService(i); else startForegroundService(i);
        });
        TextView info = text("Hudba a příběhy Českého ráje", 14, 0xffA9B9C8, false);
        LinearLayout.LayoutParams ip=new LinearLayout.LayoutParams(-1,dp(64));root.addView(info,ip);
        Button web = new Button(this); web.setText("WEB RÁDIA"); web.setAllCaps(false);
        web.setTextColor(Color.WHITE); web.setBackground(shape(0xff24374B,dp(12)));
        root.addView(web,new LinearLayout.LayoutParams(-1,dp(54)));
        web.setOnClickListener(v->open("https://www.radioceskyraj.cz"));
        Button partner = new Button(this); partner.setText("PARTNER  •  RÁJOVINY.CZ");partner.setAllCaps(false);
        partner.setTextColor(Color.WHITE);partner.setBackground(shape(0xff24374B,dp(12)));
        LinearLayout.LayoutParams pp=new LinearLayout.LayoutParams(-1,dp(54));pp.topMargin=dp(12);root.addView(partner,pp);
        partner.setOnClickListener(v->open("https://rajoviny.cz"));
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission("android.permission.POST_NOTIFICATIONS") != android.content.pm.PackageManager.PERMISSION_GRANTED)
            requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 10);
    }
    @Override protected void onStart() {
        super.onStart();
        String state = RadioService.currentState;
        status.setText(state);
        playing = state.equals("Hraje živě") || state.equals("Připojování…");
        play.setText(playing ? "■   ZASTAVIT VYSÍLÁNÍ" : "▶   PŘEHRÁT ŽIVĚ");
        IntentFilter f = new IntentFilter(RadioService.ACTION_STATE);
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver,f,Context.RECEIVER_NOT_EXPORTED);
        else registerReceiver(receiver,f);
    }
    @Override protected void onStop() { unregisterReceiver(receiver);super.onStop(); }
}
