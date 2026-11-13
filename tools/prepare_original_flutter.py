#!/usr/bin/env python3
"""Safely turn the uploaded ORIGINAL Flutter app into Rádio Český ráj.
Never uploads or uses bundled original signing/Firebase credentials."""
from pathlib import Path
from tempfile import TemporaryDirectory
import shutil, zipfile, re, sys

ROOT = Path(__file__).resolve().parents[1]
out = ROOT / "radio_cesky_raj"
source_zips = [ROOT / "RADIO_CESKY_RAJ_ANDROID.zip", ROOT / "rohozec_radio (2).zip"]
archive = next((p for p in source_zips if p.is_file()), None)
if archive is None:
    sys.exit("Missing app project ZIP. Upload 'RADIO_CESKY_RAJ_ANDROID.zip' or 'rohozec_radio (2).zip'.")
if out.exists():
    shutil.rmtree(out)
with TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    with zipfile.ZipFile(archive) as z:
        for item in z.infolist():
            target = (tmp / item.filename).resolve()
            if not target.is_relative_to(tmp.resolve()):
                sys.exit("Unsafe archive path: " + item.filename)
        z.extractall(tmp)
    choices = [p.parent for p in tmp.rglob("pubspec.yaml")
               if (p.parent / "lib/main.dart").is_file() and (p.parent / "android/app/build.gradle").is_file()]
    if not choices:
        sys.exit("Archive does not contain a Flutter Android project.")
    choices.sort(key=lambda p: len(p.parts))
    origin = choices[0]
    shutil.copytree(origin, out, ignore=shutil.ignore_patterns(
        "*.jks", "key.properties", "google-services.json", "GoogleService-Info.plist",
        "firebase_app_id_file.json", ".DS_Store", ".dart_tool", ".gradle", "build", ".git"))

def read(rel):
    return (out / rel).read_text(encoding="utf-8")
def write(rel, s):
    p = out / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")

# Keep every original screen and widget, replacing only station-specific settings.
write("lib/config.dart", """class Config {
  static const title = 'Rádio Český ráj';
  static const description = 'Náš kraj. Naše hudba. Váš den.';
  static const streamUrl = 'https://portal.juke-box.cz:2020/stream/radioceskyraj';
  static const website = 'https://www.radioceskyraj.cz/';
  static const partnerWebsite = 'https://rajoviny.cz/';
  static const instagram = '';
  static const facebook = '';
  static const email = '';
  static const shareSubject = 'Rádio Český ráj';
  static const shareText = 'Poslouchám Rádio Český ráj. https://www.radioceskyraj.cz/';
  static const appStoreId = '0123456789';
  static const autoplay = false;
  // MediaCP is the single authoritative artwork source; no iTunes mismatch.
  static const showAlbumCover = false;
  static const albumCoverFromItunes = false;
  static const textScrolling = true;
  static const metadataUrl = '';
  static const artistTag = 'artist';
  static const trackTag = 'title';
  static const coverTag = 'thumb';
  static const titleTag = '';
  static const titleSeparator = ' - ';
  static const timerPeriod = 2;
}
""")
s = read("lib/main.dart")
s = s.replace("import 'package:single_radio/services/fcm_service.dart';\n", "")
s = s.replace("  await FcmService.init();\n", "")
write("lib/main.dart", s)
s = read("lib/language.dart")
s = s.replace("static const website = 'Webová stránka';", "static const website = 'Web rádia';")
s = s.replace("static const privacyPolicy = 'Pravidla ochrany osobních údajů';",
              "static const privacyPolicy = 'Zásady ochrany soukromí';")
write("lib/language.dart", s)
s = read("lib/widgets/sidebar.dart")

def remove_item_containing(source, marker):
    """Remove one active Dart _Item(...) constructor containing marker."""
    marker_pos = source.find(marker)
    if marker_pos < 0:
        return source, 0
    start = source.rfind("_Item(", 0, marker_pos)
    if start < 0:
        return source, 0
    line_start = source.rfind("\n", 0, start) + 1
    if source[line_start:start].lstrip().startswith("//"):
        return source, 0

    depth = 0
    quote = None
    triple = False
    line_comment = False
    block_comment = False
    i = start + len("_Item")
    end = None
    while i < len(source):
        if line_comment:
            if source[i] == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if source.startswith("*/", i):
                block_comment = False
                i += 2
            else:
                i += 1
            continue
        if quote is not None:
            if source[i] == "\\":
                i += 2
                continue
            if triple and source.startswith(quote * 3, i):
                quote = None
                triple = False
                i += 3
                continue
            if not triple and source[i] == quote:
                quote = None
            i += 1
            continue
        if source.startswith("//", i):
            line_comment = True
            i += 2
            continue
        if source.startswith("/*", i):
            block_comment = True
            i += 2
            continue
        if source[i] in ("'", '"'):
            quote = source[i]
            triple = source.startswith(quote * 3, i)
            i += 3 if triple else 1
            continue
        if source[i] == "(":
            depth += 1
        elif source[i] == ")":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
        i += 1

    if end is None:
        sys.exit("STOP: Could not safely parse the matching drawer item.")
    if marker not in source[start:end]:
        return source, 0

    remove_start = line_start if not source[line_start:start].strip() else start
    tail = end
    while tail < len(source) and source[tail] in " \t":
        tail += 1
    if tail < len(source) and source[tail] == ",":
        tail += 1
    if tail < len(source) and source[tail] == "\r":
        tail += 1
    if tail < len(source) and source[tail] == "\n":
        tail += 1
    return source[:remove_start] + source[tail:], 1

# Rájoviny belongs in the dedicated bottom navigation, not duplicated in
# the drawer. Match the real constructor by its destination, not formatting.
s, removed_partner = remove_item_containing(s, "Config.partnerWebsite")
if not removed_partner:
    s, removed_partner = remove_item_containing(s, "Rájoviny.cz")
if not removed_partner:
    print("DRAWER: no active Rájoviny _Item constructor found; leaving source unchanged.")

# Never add an app-rating prompt. Remove an active rating row if the source
# contains one; commented-out legacy examples are not treated as UI entries.
s, removed_rating = remove_item_containing(s, "Language.rateUs")
if not removed_rating:
    s, removed_rating = remove_item_containing(s, "inAppReview.openStoreListing")
write("lib/widgets/sidebar.dart", s)
print(f"DRAWER CLEANUP: partner_items={removed_partner}, rating_items={removed_rating}")


# Change the sidebar's privacy entry from a modal dialog into a proper
# screen. Preserve the original player route; the audio view model is shared.
s = read("lib/widgets/sidebar.dart")
s = s.replace("import 'package:single_radio/widgets/markdown.dart';\n",
              "import 'package:single_radio/screens/privacy/privacy_view.dart';\n")
# Replace the onTap show's Dialog; do not alter any other sidebar item.
s, privacy_changes = re.subn(
    r"(?ms)^          showDialog\(.*?^          \);",
    "          Navigator.pushNamed(context, PrivacyView.routeName);",
    s,
    count=1,
)
if privacy_changes != 1:
    sys.exit("STOP: original privacy Dialog not found; do not write sidebar")
write("lib/widgets/sidebar.dart", s)

# Sidebar artwork is already replaced with the station icon by the
# existing verified asset-generation block above. Keep its original layout.

s = read("lib/main.dart")
import_anchor = "import 'package:single_radio/screens/about/about_view.dart';"
if import_anchor not in s:
    sys.exit("STOP: original Flutter router was changed")
s = s.replace(import_anchor,
    import_anchor + "\nimport 'package:single_radio/screens/privacy/privacy_view.dart';")
route_anchor = "      case AboutView.routeName:"
if route_anchor not in s:
    sys.exit("STOP: cannot find original AboutView navigation")
s = s.replace(route_anchor,
    "      case PrivacyView.routeName:\n"
    "        return MaterialPageRoute(\n"
    "          builder: (context) => const PrivacyView(),\n"
    "        );\n" + route_anchor)
write("lib/main.dart", s)

privacy_template = ROOT / "tools/templates/privacy_view.dart"
if not privacy_template.is_file():
    sys.exit("STOP: missing native privacy page template")
write("lib/screens/privacy/privacy_view.dart", privacy_template.read_text(encoding="utf-8"))
print("NATIVE PRIVACY SCREEN REGISTERED as /privacy; no MarkdownDialog overlay")

# Premium startup screen: display the user-approved full portrait artwork in
# Flutter immediately after Android's mandatory system splash. This is required
# on Android 12+, which only permits a centered icon during the native phase.
premium_asset = ROOT / "assets/branding/rcr_premium_splash.webp"
if not premium_asset.is_file() or premium_asset.stat().st_size < 6000:
    sys.exit("STOP: approved premium splash image is not present in repository")
shutil.copy2(premium_asset, out / "assets/images/rcr_premium_splash.webp")
main_file = read("lib/main.dart")
import_anchor = "import 'package:single_radio/config.dart';"
if main_file.count(import_anchor) != 1:
    sys.exit("STOP: original Flutter main.dart import changed")
main_file = main_file.replace(import_anchor, import_anchor + "\nimport 'package:single_radio/screens/startup/rcr_startup_splash.dart';")
builder_anchor = "        theme: AppTheme.themeData,"
if main_file.count(builder_anchor) != 1:
    sys.exit("STOP: original Flutter app builder changed")
main_file = main_file.replace(builder_anchor,
    builder_anchor + "\n        builder: (context, child) => RcrStartupSplash(child: child ?? const SizedBox.shrink()),")
write("lib/main.dart", main_file)
splash_dart = ROOT / "tools/templates/rcr_startup_splash.dart"
if not splash_dart.is_file():
    sys.exit("STOP: premium Flutter startup overlay template missing")
write("lib/screens/startup/rcr_startup_splash.dart", splash_dart.read_text(encoding="utf-8"))
print("PREMIUM SPLASH: full-screen approved portrait artwork will appear after native Android launch")


s = read("lib/theme.dart")
colors = {
    "0xFF141C27":"0xFF101A27",
    "0xFF172230":"0xFF142131",
    "0xFF323d23":"0xFFA6E81C",
    "0xFFE91E63":"0xFF36C66A",
    "0xFF019EF6":"0xFFA6E81C",
    "0xFF2196F3":"0xFFA6E81C",
    "0xFFBBDEFB":"0xFF34465A",
}
for a,b in colors.items():
    s = s.replace(a,b)
write("lib/theme.dart", s)
s = read("pubspec.yaml")
for line in ["  firebase_core: ^2.13.1\n",
             "  firebase_messaging: ^14.6.2\n",
             "  flutter_local_notifications: 13.0.0\n"]:
    s = s.replace(line, "")
s = re.sub(r"(?m)^version:\s*[^\n]+", "version: 2.8.3+44", s)
s = s.replace('#FFFFFFFF', '#101A27').replace('#323d23', '#142131')
write("pubspec.yaml", s)
s = read("android/build.gradle")
s = re.sub(r"(?m)^.*com\.google\.gms:google-services.*\n","",s)
write("android/build.gradle", s)
s = read("android/app/build.gradle")
s = re.sub(r"(?m)^apply plugin: 'com\.google\.gms\.google-services'\n", "", s)
s = re.sub(r"(?m)^\s*implementation platform\('com\.google\.firebase:[^\n]+\n", "", s)
s = re.sub(r"(?m)^\s*implementation 'com\.google\.firebase:[^\n]+\n", "", s)
s = re.sub(r'applicationId\s+"[^"]+"', 'applicationId "cz.radioceskyraj.radio"', s)
# Don't accidentally use original keystore or null release signing data.
s = re.sub(r"(?ms)^    signingConfigs \{.*?^    \}\n\n    buildTypes \{.*?^    \}",
"""    signingConfigs {
        release {
            if (keystorePropertiesFile.exists() && keystoreProperties['storeFile']) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig signingConfigs.release
            }
        }
    }""",s)
write("android/app/build.gradle", s)

# API 35 prevents Android's old-target privacy warning and is compatible
# with Android 16 (API 36), without pretending this old Flutter 3.7 project
# has already been migrated to targetSdk 36.
s=read("android/app/build.gradle")
s=s.replace("compileSdkVersion 33","compileSdkVersion 35")
s=s.replace("targetSdkVersion 33","targetSdkVersion 35")
write("android/app/build.gradle",s)
gradle_props=read("android/gradle.properties")
if "android.suppressUnsupportedCompileSdk" not in gradle_props:
    gradle_props+="\nandroid.suppressUnsupportedCompileSdk=35\n"
write("android/gradle.properties",gradle_props)

s = read("android/app/src/main/AndroidManifest.xml")
s = s.replace('android:label="Radio Rohozec"', 'android:label="Rádio Český ráj"')
s = s.replace('android:label="Rádio Rohozec"', 'android:label="Rádio Český ráj"')
# Preserve full station name on the launcher.
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET" />\n    <application', 1)
s = re.sub(r'(?ms)        <meta-data\s+android:name="com\.google\.firebase\..*?/>', '', s)
write("android/app/src/main/AndroidManifest.xml",s)
# Android 14+ requires a declared mediaPlayback foreground-service type and
# matching permission, independent from receiver export flags.
s=read("android/app/src/main/AndroidManifest.xml")
if 'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK' not in s:
    s=s.replace('<application', '''<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <application''',1)
service_tag='''<service
            android:name="com.cheebeez.radio_player.RadioPlayerService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />'''
if 'com.cheebeez.radio_player.RadioPlayerService' not in s:
    s=s.replace('    </application>', '        '+service_tag+'\n    </application>',1)
write("android/app/src/main/AndroidManifest.xml",s)

write("assets/text/about.md", """# Rádio Český ráj

Vítejte u Rádia Český ráj. Vysíláme pro všechny, kteří mají rádi náš kraj, jeho příběhy, lidi a dobrou hudbu.

Přinášíme melodie, které vám zpříjemní den, regionální zajímavosti i vyprávění ze známých a zapomenutých míst Českého ráje.

Mediálním partnerem rádia jsou Rájoviny.cz.

**Náš kraj. Naše hudba. Váš den.**
""")
write("assets/text/privacy_policy.md", """# Zásady ochrany soukromí – Rádio Český ráj

Aplikace slouží k přehrávání internetového rádia. Nevyžaduje účet ani zadávání osobních údajů.

Přehrávání vyžaduje připojení ke streamovacímu serveru; provozovatel streamu může zpracovávat IP adresu a technické informace o připojení. Aplikace může přehrávat na pozadí.

Otevření webů https://www.radioceskyraj.cz/ a https://rajoviny.cz/ se řídí zásadami příslušných webů.

Sdílení je dobrovolné přes systémové funkce telefonu.
""")
# Logos are generated from the EXACT station artwork already uploaded to the repo
# at app/src/main/assets/icon.webp, not an invented substitute.
from PIL import Image
logo_path = ROOT / "app/src/main/assets/icon.webp"
if not logo_path.is_file():
    sys.exit("Missing station artwork from this repository: app/src/main/assets/icon.webp")
logo = Image.open(logo_path).convert("RGB")
logo = logo.resize((1024,1024), Image.Resampling.LANCZOS)
def save_image(path, wh, fmt=None):
    img = logo.resize(wh, Image.Resampling.LANCZOS)
    p=out/path
    p.parent.mkdir(parents=True,exist_ok=True)
    img.save(p, format=fmt or ("JPEG" if p.suffix.lower()==".jpg" else "PNG"),quality=94)
save_image("assets/appicon/appicon.png", (1024,1024))
save_image("assets/appicon/appicon-adaptive.png", (1024,1024))
save_image("assets/images/sidebar.png", (512,512))
save_image("assets/images/about.jpg", (1024,1024))
save_image("assets/images/splash.jpg", (1024,1024))
save_image("assets/splash/splash.png", (1024,1024))
save_image("assets/splash/splash12.png", (1024,1024))

# Professional native launch screen: exact station artwork, no added package.
# Flutter's first frame takes over from this Android-native splash automatically.
from PIL import ImageDraw, ImageFont
splash_res = out / "android/app/src/main/res"
splash_logo = Image.open(ROOT / "assets/branding/rcr_full_logo.webp").convert("RGB")
canvas = Image.new("RGB", (1080, 1920), (16, 26, 39))
pixels = canvas.load()
for y in range(1920):
    t = y / 1919
    for x in range(1080):
        dx = (x - 540) / 540
        glow = max(0, 1 - ((dx * dx + ((y - 700) / 1100) ** 2) ** 0.5))
        pixels[x, y] = (
            int(10 + 8 * glow),
            int(19 + 17 * glow),
            int(33 + 25 * glow),
        )
# Keep the entire supplied logo visible, with no crop or artificial replacement.
logo_w = 760
logo_h = round(logo_w * splash_logo.height / splash_logo.width)
splash_logo = splash_logo.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
# The original artwork has a black field; embed it on an intentional dark plaque.
plaque = Image.new("RGB", (logo_w + 72, logo_h + 72), (4, 8, 15))
canvas.paste(plaque, ((1080 - plaque.width)//2, 665 - 36))
canvas.paste(splash_logo, ((1080 - logo_w)//2, 665))
draw = ImageDraw.Draw(canvas)
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 37)
except OSError:
    font = ImageFont.load_default()
tagline = "Náš kraj. Naše hudba. Váš den."
draw.text((540, 1250), tagline, font=font, anchor="mm", fill=(216, 226, 234))
draw.rounded_rectangle((456, 1355, 624, 1361), radius=3, fill=(166, 232, 28))
nodpi = splash_res / "drawable-nodpi"
nodpi.mkdir(parents=True, exist_ok=True)
# Match the approved portrait artwork in Android's pre-Flutter launch frame.
from PIL import ImageOps
native_splash = ImageOps.pad(
    Image.open(premium_asset).convert("RGB"),
    (1080, 1920),
    method=Image.Resampling.LANCZOS,
    color=(6, 19, 41),
    centering=(0.5, 0.5),
)
native_splash.save(nodpi / "rcr_launch_art.png", optimize=True)
# Android 12+ imposes a centered icon; give it generous safe padding.
icon = Image.new("RGBA", (432, 432), (16, 26, 39, 255))
safe_w = 276
safe_h = round(safe_w * splash_logo.height / splash_logo.width)
safe_logo = splash_logo.resize((safe_w, safe_h), Image.Resampling.LANCZOS)
icon.paste(safe_logo, ((432-safe_w)//2, (432-safe_h)//2))
icon.save(nodpi / "rcr_splash_icon.png", optimize=True)
launch_xml = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/rcr_splash_background" />
    <item>
        <bitmap android:gravity="fill" android:src="@drawable/rcr_launch_art" />
    </item>
</layer-list>
"""
for folder in ("drawable", "drawable-v21"):
    p = splash_res / folder / "launch_background.xml"
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(launch_xml, encoding="utf-8")
# Keep the original Android styles and modify only LaunchTheme.
import xml.etree.ElementTree as ET
ns = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ns)
def update_launch_style(folder, android12=False):
    p = splash_res / folder / "styles.xml"
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists():
        root = ET.parse(p).getroot()
    else:
        root = ET.Element("resources")
    launch = next((e for e in root.findall("style") if e.get("name") == "LaunchTheme"), None)
    if launch is None:
        launch = ET.SubElement(root, "style", {"name": "LaunchTheme", "parent": "@android:style/Theme.Material.Light.NoActionBar"})
    def item(name, value):
        for old in list(launch.findall("item")):
            if old.get("name") == name:
                launch.remove(old)
        ET.SubElement(launch, "item", {"name": name}).text = value
    item("android:windowBackground", "@drawable/launch_background")
    item("android:windowLightStatusBar", "false")
    item("android:statusBarColor", "@color/rcr_splash_background")
    item("android:navigationBarColor", "@color/rcr_splash_background")
    if android12:
        item("android:windowSplashScreenBackground", "@color/rcr_splash_background")
        item("android:windowSplashScreenAnimatedIcon", "@drawable/rcr_splash_icon")
        item("android:windowSplashScreenIconBackgroundColor", "@color/rcr_splash_background")
    ET.ElementTree(root).write(p, encoding="utf-8", xml_declaration=True)
update_launch_style("values")
update_launch_style("values-v31", android12=True)
# New color belongs to the existing colors.xml and must not be overwritten below.
print("PRO SPLASH: exact logo, native pre-Android-12 artwork and Android-12+ launch icon installed")

# Previous releases accidentally retained ORIGINAL brewery Android launcher icons
# in res/mipmap-* and adaptive icon foregrounds. Replace every raster resource.
# This is separate from Flutter's assets/appicon and MUST happen before compilation.
android_res = out / "android/app/src/main/res"
density_scale = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0,
                 "xxhdpi": 3.0, "xxxhdpi": 4.0}
bg=(16,26,39,255)
rgba = logo.convert("RGBA")
for density, scale in density_scale.items():
    n = int(48*scale)
    mip = android_res/f"mipmap-{density}"
    mip.mkdir(parents=True, exist_ok=True)
    for name in ("ic_launcher.png", "ic_launcher_round.png"):
        rgba.resize((n,n), Image.Resampling.LANCZOS).save(mip/name)
    # Adaptive icon foreground: safe padding, background remains official navy.
    nfg=int(108*scale)
    fg=Image.new("RGBA",(nfg,nfg),bg)
    margin=int(nfg*0.10)
    fg.alpha_composite(rgba.resize((nfg-2*margin,nfg-2*margin),Image.Resampling.LANCZOS),(margin,margin))
    fg.save(mip/"ic_launcher_foreground.png")
    drawable=android_res/f"drawable-{density}"
    drawable.mkdir(parents=True,exist_ok=True)
    fg.save(drawable/"ic_launcher_foreground.png")
    # Splash assets were also still using the Rohozec crest.
    for is_night in (False,True):
        drawable=(android_res/f"drawable{'-night' if is_night else ''}-{density}")
        drawable.mkdir(parents=True,exist_ok=True)
        splash=Image.new("RGBA",(int(320*scale),int(320*scale)),bg)
        symbol=rgba.resize((int(250*scale),int(250*scale)),Image.Resampling.LANCZOS)
        splash.alpha_composite(symbol,((splash.width-symbol.width)//2,(splash.height-symbol.height)//2))
        splash.save(drawable/"splash.png")
        splash.save(drawable/"android12splash.png")
# Replace old light/dark launch background images as well.
for p in android_res.rglob("background.png"):
    if "drawable" in p.parent.name:
        rgba.resize((512,512),Image.Resampling.LANCZOS).save(p)
# A monochrome adaptive icon must not retain the old brewery mark.
monochrome=android_res/"drawable/ic_launcher_monochrome.png"
if monochrome.exists():
    monochrome.unlink()
for fname in ("ic_launcher.xml","ic_launcher_round.xml"):
    p=android_res/"mipmap-anydpi-v26"/fname
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text("""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background" />
  <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
""", encoding="utf-8")
colors=android_res/"values/colors.xml"
colors.parent.mkdir(parents=True,exist_ok=True)
colors.write_text("""<?xml version="1.0" encoding="utf-8"?>
<resources><color name="ic_launcher_background">#101A27</color><color name="rcr_splash_background">#101A27</color></resources>
""", encoding="utf-8")
save_image("android/app/src/main/ic_launcher-playstore.png",(512,512))
save_image("assets/images/rcr_logo.png",(1024,1024))
# No brewery-logo png must survive in launcher/splash Android resource folders.
for p in android_res.rglob("*.png"):
    if p.name in ("ic_launcher.png","ic_launcher_round.png","ic_launcher_foreground.png",
                  "splash.png","android12splash.png","background.png"):
        from PIL import ImageStat
        im=Image.open(p).convert("RGB")
        rr,gg,bb=ImageStat.Stat(im).mean
        if rr > gg*1.75 and rr > bb*1.6:
            sys.exit("Old brewery-colored Android asset detected: "+str(p))
print("ALL Android launcher and splash resources replaced with station artwork")

# Exact user-supplied WIDE radio logo, recovered from GitHub blob
# and checked using SHA-256 before any APK can be published.
import hashlib
full_logo=ROOT/"assets/branding/rcr_full_logo.webp"
expected_logo_sha="9512a4daa057cd148d1da6562d3f3e41d60d8ce7da683c1d87fd416fdbf1434a"
if not full_logo.is_file() or hashlib.sha256(full_logo.read_bytes()).hexdigest()!=expected_logo_sha:
    sys.exit("STOP: Exact full Rádio Český ráj logo missing or modified")
station_logo=Image.open(full_logo).convert("RGB")
if station_logo.size!=(600,352):
    sys.exit("STOP: Incorrect wide logo dimensions")
station_logo.save(out/"assets/images/rcr_full_logo.png",optimize=True)
print("FULL RADIO LOGO VERIFIED and installed inside original Flutter assets")

# Fix the player itself: station logo always complete and uncropped.
# Show the cover of a real song only as a secondary image, when available.
player=read("lib/screens/player/player_view.dart")
old_player="""          const ExpandedBox(flex: 2, minHeight: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _Cover(
              key: viewModel.artwork?.key,
              size: MediaQuery.of(context).size.width - padding * 2,
              image: viewModel.artwork ??
                  Image.asset(
                    'assets/appicon/appicon.png',
                    fit: BoxFit.cover,
                  ),
            ),
          ),
          const ExpandedBox(flex: 4, minHeight: 40),"""
new_player="""          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 600 / 352,
            child: Image.asset(
              'assets/images/rcr_full_logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 14),
          if (viewModel.artwork != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: _Cover(
                key: viewModel.artwork?.key,
                size: (MediaQuery.of(context).size.width - padding * 2) * 0.59,
                image: viewModel.artwork!,
              ),
            ),
            const SizedBox(height: 15),
          ],
          const SizedBox(height: 22),"""
if old_player not in player:
    sys.exit("STOP: Original Flutter player structure changed; no UI replacement attempted")
player=player.replace(old_player,new_player)
write("lib/screens/player/player_view.dart",player)

# Search iTunes only for plausible musician/song pairs. News, fairy tales
# and regional programmes must never display a misleading album cover.
vm=read("lib/screens/player/player_viewmodel.dart")
old_metadata="""      log(metadata.toString());
      metadata = value;
      if (Config.showAlbumCover) artwork = await _radioPlayer.getArtworkImage();
      notifyListeners();"""
new_metadata="""      metadata = value;
      final requestId = ++_artworkRequestId;
      artwork = null;
      notifyListeners();
      if (!Config.showAlbumCover || value.length < 2) return;
      // Keep all MediaCP metadata exactly as received. A long, unusual,
      // or all-caps title can still be a real song title; never blacklist it.
      if (value[0].trim().isEmpty || value[1].trim().isEmpty) return;
      try {
        final cover = await _radioPlayer.getArtworkImage();
        if (requestId != _artworkRequestId) return;
        artwork = cover;
        notifyListeners();
      } catch (error) {
        log('Artwork lookup unavailable: $error');
      }"""
if old_metadata not in vm:
    sys.exit("STOP: Original metadata listener changed")
vm=vm.replace("  Image? artwork;", "  Image? artwork;\n  int _artworkRequestId = 0;", 1)
vm=vm.replace(old_metadata,new_metadata)
write("lib/screens/player/player_viewmodel.dart",vm)
print("Original player now uses exact wide station logo + optional real music artwork")

# Apply professionally balanced Flutter screens after original audio/metadata logic.
# This preserves the original PlayerViewModel and all service code.
for template, destination in [
    ("tools/templates/player_view.dart", "lib/screens/player/player_view.dart"),
    ("tools/templates/about_view.dart", "lib/screens/about/about_view.dart"),
]:
    template_path=ROOT/template
    if not template_path.is_file():
        sys.exit("STOP: Missing original-app layout template: "+template)
    source=template_path.read_text(encoding="utf-8")
    if destination.endswith("player_view.dart") and "MediaCpCover()" not in source:
        sys.exit("STOP: Player MediaCP artwork component missing")
    if destination.endswith("about_view.dart") and "rcr_full_logo.png" not in source:
        sys.exit("STOP: About logo source missing")
    write(destination, source)
# Public MediaCP cover-art fetcher; full RCR logo on invalid/missing cover.
cover_template = ROOT / "tools/templates/mediacp_cover.dart"
if not cover_template.is_file():
    sys.exit("STOP: MediaCP cover widget is missing")
cover_source = cover_template.read_text(encoding="utf-8")
assert "json/stream/radioceskyraj" in cover_source
assert "rcr_full_logo.png" in cover_source
write("lib/screens/player/mediacp_cover.dart", cover_source)
assert "MediaCpCover()" in read("lib/screens/player/player_view.dart")
print("OFFICIAL MEDIACP COVER ART ENABLED with fallback, original radio playback untouched")
print("REDESIGNED: large rotating vinyl with live song cover, clean navigation and premium About page")




# Keep the proven original Flutter player unchanged in this privacy-screen fix.
# A separate redesign of full-width branding and artwork must be tested independently.
# Make source brand search fail loudly rather than publishing a brewery app.
for test in ["lib/config.dart", "assets/text/about.md", "assets/text/privacy_policy.md"]:
    if any(w in read(test).lower() for w in ("rohozec", "pivovar")):
        sys.exit("Original brewery branding left in: " + test)
assert (out/"lib/screens/player/player_view.dart").is_file()
assert (out/"lib/screens/timer/timer_view.dart").is_file()
print("ORIGINAL FLUTTER APP READY:",out)
print("Original audio engine and timer preserved; premium player and About screens installed.")
print("Original signing and Firebase credential files excluded.")
