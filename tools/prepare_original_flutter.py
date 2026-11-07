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
s = re.sub(r"(?m)^version:\s*[^\n]+", "version: 1.9.0+25", s)
s = s.replace('#FFFFFFFF', '#101A27').replace('#323d23', '#142131')
write("pubspec.yaml", s)
s = read("android/build.gradle")
s = re.sub(r"(?m)^.*com\.google\.gms:google-services.*\n","",s)
write("android/build.gradle", s)
s = read("android/app/build.gradle")
s = re.sub(r"(?m)^apply plugin: 'com\.google\.gms\.google-services'\n", "", s)
s = re.sub(r"(?m)^\s*implementation platform\('com\.google\.firebase:[^\n]+\n", "", s)
s = re.sub(r"(?m)^\s*implementation 'com\.google\.firebase:[^\n]+\n", "", s)
s = re.sub(r'applicationId\s+"[^"]+"', 'applicationId "cz.radioceskyraj.original"', s)
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
# Make source brand search fail loudly rather than publishing a brewery app.
for test in ["lib/config.dart", "assets/text/about.md", "assets/text/privacy_policy.md"]:
    if any(w in read(test).lower() for w in ("rohozec", "pivovar")):
        sys.exit("Original brewery branding left in: " + test)
assert (out/"lib/screens/player/player_view.dart").is_file()
assert (out/"lib/screens/timer/timer_view.dart").is_file()
print("ORIGINAL FLUTTER APP READY:",out)
print("UNCHANGED screens: player, timer, about")
print("Original signing and Firebase credential files excluded.")
