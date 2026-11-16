#!/usr/bin/env python3
"""Prepare the shared Rádio Český ráj Flutter app for an unsigned iOS simulator build."""
from pathlib import Path
import json
import plistlib
import re
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "radio_cesky_raj"
IOS = PROJECT / "ios"

def stop(message):
    sys.exit("STOP: " + message)

if not (PROJECT / "pubspec.yaml").is_file():
    stop("prepared Flutter project is missing")
if not (IOS / "Runner.xcodeproj/project.pbxproj").is_file():
    stop("Flutter did not generate the iOS Runner project")

splash_src = PROJECT / "assets/images/rcr_premium_splash.webp"
if not splash_src.is_file():
    stop("approved full-screen splash artwork missing")
icon_src = PROJECT / "assets/appicon/appicon.png"
if not icon_src.is_file():
    stop("original Rádio Český ráj app icon missing")

# Generate the iOS app icon set from the station's actual square logo asset.
appicon = IOS / "Runner/Assets.xcassets/AppIcon.appiconset"
appicon.mkdir(parents=True, exist_ok=True)
source = Image.open(icon_src).convert("RGBA")
background = Image.new("RGBA", source.size, (6, 19, 41, 255))
background.alpha_composite(source)
base = background.convert("RGB")
images = []
for idiom, point_size, scale in [
    ("iphone", "20x20", 2), ("iphone", "20x20", 3),
    ("iphone", "29x29", 2), ("iphone", "29x29", 3),
    ("iphone", "40x40", 2), ("iphone", "40x40", 3),
    ("iphone", "60x60", 2), ("iphone", "60x60", 3),
    ("ipad", "20x20", 1), ("ipad", "20x20", 2),
    ("ipad", "29x29", 1), ("ipad", "29x29", 2),
    ("ipad", "40x40", 1), ("ipad", "40x40", 2),
    ("ipad", "76x76", 1), ("ipad", "76x76", 2),
    ("ipad", "83.5x83.5", 2),
]:
    pixels = round(float(point_size.split("x")[0]) * scale)
    filename = f"Icon-{idiom}-{point_size.replace('.', '_')}-{scale}x.png"
    base.resize((pixels, pixels), Image.Resampling.LANCZOS).save(appicon / filename, optimize=True)
    images.append({"filename": filename, "idiom": idiom, "scale": f"{scale}x", "size": point_size})
marketing = "Icon-AppStore-1024.png"
base.resize((1024, 1024), Image.Resampling.LANCZOS).save(appicon / marketing, optimize=True)
images.append({"filename": marketing, "idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"})
(appicon / "Contents.json").write_text(
    json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2),
    encoding="utf-8",
)

# Reuse the approved portrait artwork in the native iOS launch storyboard.
launch_set = IOS / "Runner/Assets.xcassets/RCRLaunchScreen.imageset"
launch_set.mkdir(parents=True, exist_ok=True)
Image.open(splash_src).convert("RGB").save(launch_set / "RCRLaunchScreen.png", optimize=True)
(launch_set / "Contents.json").write_text(json.dumps({
    "images": [{"filename": "RCRLaunchScreen.png", "idiom": "universal"}],
    "info": {"author": "xcode", "version": 1}
}, indent=2), encoding="utf-8")

storyboard = """<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="23094" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" colorMatched="YES" initialViewController="rcr-launch-vc">
    <device id="retina6_12" orientation="portrait" appearance="dark"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="23084"/>
    </dependencies>
    <scenes>
        <scene sceneID="rcr-launch-scene">
            <objects>
                <viewController id="rcr-launch-vc" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="rcr-launch-root">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" image="RCRLaunchScreen" translatesAutoresizingMaskIntoConstraints="NO" id="rcr-launch-image">
                                <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                            </imageView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="rcr-launch-safe"/>
                        <color key="backgroundColor" red="0.0235" green="0.0745" blue="0.1608" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="rcr-launch-image" firstAttribute="top" secondItem="rcr-launch-root" secondAttribute="top" id="rcr-top"/>
                            <constraint firstItem="rcr-launch-image" firstAttribute="bottom" secondItem="rcr-launch-root" secondAttribute="bottom" id="rcr-bottom"/>
                            <constraint firstItem="rcr-launch-image" firstAttribute="leading" secondItem="rcr-launch-root" secondAttribute="leading" id="rcr-leading"/>
                            <constraint firstItem="rcr-launch-image" firstAttribute="trailing" secondItem="rcr-launch-root" secondAttribute="trailing" id="rcr-trailing"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="rcr-first-responder" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
        </scene>
    </scenes>
    <resources>
        <image name="RCRLaunchScreen" width="400" height="711"/>
    </resources>
</document>
"""
(IOS / "Runner/Base.lproj/LaunchScreen.storyboard").write_text(storyboard, encoding="utf-8")

# Keep the same app identity and enable audio playback while the app is in background.
info_path = IOS / "Runner/Info.plist"
with info_path.open("rb") as f:
    info = plistlib.load(f)
info["CFBundleDisplayName"] = "Rádio Český ráj"
info["CFBundleName"] = "Rádio Český ráj"
info["UIBackgroundModes"] = sorted(set(info.get("UIBackgroundModes", []) + ["audio"]))
info["ITSAppUsesNonExemptEncryption"] = False
with info_path.open("wb") as f:
    plistlib.dump(info, f, sort_keys=False)

# Stable bundle ID for later signing. Simulator builds remain completely unsigned.
pbx_path = IOS / "Runner.xcodeproj/project.pbxproj"
pbx = pbx_path.read_text(encoding="utf-8")

# The original Android-derived project retained an Xcode resource reference to
# a private Firebase plist. The preparation deliberately excludes that secret
# file, and Firebase packages are removed from pubspec, so remove only the
# stale Xcode project lines that refer to this absent resource.
pbx_lines = pbx.splitlines()
pbx_lines_before = len(pbx_lines)
pbx_lines = [line for line in pbx_lines if "GoogleService-Info.plist" not in line]
if len(pbx_lines) == pbx_lines_before and "GoogleService-Info.plist" in pbx:
    sys.exit("STOP: could not safely remove stale GoogleService-Info.plist references")
pbx = "\\n".join(pbx_lines) + "\\n"
if "GoogleService-Info.plist" in pbx:
    sys.exit("STOP: stale GoogleService-Info.plist reference remains")
pbx, count = re.subn(
    r"PRODUCT_BUNDLE_IDENTIFIER = [^;]+;",
    "PRODUCT_BUNDLE_IDENTIFIER = cz.radioceskyraj.radio;",
    pbx,
)
if count < 1:
    stop("could not set the iOS bundle identifier")
pbx = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [^;]+;", "IPHONEOS_DEPLOYMENT_TARGET = 12.0;", pbx)
pbx_path.write_text(pbx, encoding="utf-8")

podfile = IOS / "Podfile"
if podfile.is_file():
    text = podfile.read_text(encoding="utf-8")
    text = re.sub(r"platform :ios, ['\"][^'\"]+['\"]", "platform :ios, '12.0'", text)
    if "platform :ios" not in text:
        text = "platform :ios, '12.0'\n" + text
    podfile.write_text(text, encoding="utf-8")

print("Removed stale Firebase plist reference from iOS project (no Firebase package is used).")\nprint("iOS project configured: Rádio Český ráj, original icon, approved splash,")
print("3.62-second Flutter startup, background audio, bundle ID cz.radioceskyraj.radio.")
print("No Apple Developer account, certificate, provisioning profile, or signing is used.")
