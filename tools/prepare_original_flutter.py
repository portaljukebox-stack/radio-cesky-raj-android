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
  static const showAlbumCover = true;
  static const albumCoverFromItunes = true;
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
if "Config.partnerWebsite" not in s:
    partner = """      // Regionální mediální partner
      _Item(
        icon: Icons.article_outlined,
        title: 'Rájoviny.cz – mediální partner',
        onTap: () async {
          Navigator.pop(context);
          await launchUrl(Uri.parse(Config.partnerWebsite),
              mode: LaunchMode.externalApplication);
        },
      ),

"""
    if "      // Email" not in s:
        sys.exit("Unexpected sidebar structure; will not discard original layout.")
    s = s.replace("      // Email", partner + "      // Email", 1)
write("lib/widgets/sidebar.dart", s)
# Change the sidebar's privacy entry from a modal dialog into a proper
# screen. Preserve the original player route; the audio view model is shared.
s = read("lib/widgets/sidebar.dart")
s = s.replace("import 'package:single_radio/widgets/markdown.dart';\n",
              "import 'package:single_radio/screens/privacy/privacy_view.dart';\n")
privacy_start = s.find("          showDialog(")
privacy_end = s.find("\n            },\n          ),", privacy_start)
if privacy_start < 0 or privacy_end < 0:
    sys.exit("STOP: privacy dialog navigation in original Sidebar not recognized")
# The onTap closes Drawer first, then pushes a regular MaterialPageRoute.
s = s[:privacy_start] + "          Navigator.pushNamed(context, PrivacyView.routeName);" + s[privacy_end:]
write("lib/widgets/sidebar.dart", s)

s = read("lib/main.dart")
import_anchor = "import 'package:single_radio/screens/about/about_view.dart';"
if import_anchor not in s:
    sys.exit("STOP: original Flutter router was changed")
s = s.replace(import_anchor,
    import_anchor + "\\nimport 'package:single_radio/screens/privacy/privacy_view.dart';")
route_anchor = "      case AboutView.routeName:"
if route_anchor not in s:
    sys.exit("STOP: cannot find original AboutView navigation")
s = s.replace(route_anchor,
    "      case PrivacyView.routeName:\\n"
    "        return MaterialPageRoute(\\n"
    "          builder: (context) => const PrivacyView(),\\n"
    "        );\\n" + route_anchor)
write("lib/main.dart", s)

privacy_template = ROOT / "tools/templates/privacy_view.dart"
if not privacy_template.is_file():
    sys.exit("STOP: missing native privacy page template")
write("lib/screens/privacy/privacy_view.dart", privacy_template.read_text(encoding="utf-8"))
print("NATIVE PRIVACY SCREEN REGISTERED as /privacy; no MarkdownDialog overlay")

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
s = re.sub(r"(?m)^version:\s*[^\n]+", "version: 2.1.0+32", s)
s = s.replace('#FFFFFFFF', '#101A27').replace('#323d23', '#142131')
write("pubspec.yaml", s)
s = read("android/build.gradle")
s = re.sub(r"(?m)^.*com\.google\.gms:google-services.*\n","",s)
write("android/build.gradle", s)
s = read("android/app/build.gradle")
s = re.sub(r"(?m)^apply plugin: 'com\.google\.gms\.google-services'\n", "", s)
s = re.sub(r"(?m)^\s*implementation platform\('com\.google\.firebase:[^\n]+\n", "", s)
s = re.sub(r"(?m)^\s*implementation 'com\.google\.firebase:[^\n]+\n", "", s)
s = re.sub(r'applicationId\s+"[^"]+"', 'applicationId "cz.radioceskyraj.flutter2026"', s)
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
s = read("android/app/src/main/AndroidManifest.xml")
s = s.replace('android:label="Radio Rohozec"', 'android:label="Rádio Český ráj"')
s = s.replace('android:label="Rádio Rohozec"', 'android:label="Rádio Český ráj"')
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET" />\n    <application', 1)
s = re.sub(r'(?ms)        <meta-data\s+android:name="com\.google\.firebase\..*?/>', '', s)
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
<resources><color name="ic_launcher_background">#101A27</color></resources>
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


# Keep the proven original Flutter player unchanged in this privacy-screen fix.
# A separate redesign of full-width branding and artwork must be tested independently.
# Make source brand search fail loudly rather than publishing a brewery app.
for test in ["lib/config.dart", "assets/text/about.md", "assets/text/privacy_policy.md"]:
    if any(w in read(test).lower() for w in ("rohozec", "pivovar")):
        sys.exit("Original brewery branding left in: " + test)
assert (out/"lib/screens/player/player_view.dart").is_file()
assert (out/"lib/screens/timer/timer_view.dart").is_file()
print("ORIGINAL FLUTTER APP READY:",out)
print("UNCHANGED screens: player, timer, about")
print("Original signing and Firebase credential files excluded.")
