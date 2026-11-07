#!/usr/bin/env python3
"""Restore a single lost base64 symbol in the uploaded exact station artwork.
Cryptographic SHA-256 prevents accepting even one incorrect pixel/byte."""
import base64, hashlib, sys
from pathlib import Path
source=Path("assets/branding/rcr_full_logo.webp")
expected="9512a4daa057cd148d1da6562d3f3e41d60d8ce7da683c1d87fd416fdbf1434a"
raw=source.read_bytes()
sha=lambda b:hashlib.sha256(b).hexdigest()
if sha(raw)==expected:
    print("Full radio logo verified",len(raw))
    raise SystemExit(0)
alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
b=base64.b64encode(raw).decode("ascii")
print("Validating input logo source",len(raw),"bytes",len(b),"base64 characters")
if len(b)!=8908:
    raise SystemExit("Logo bytes unexpected; refusing to generate substitute artwork")
# The historical GitHub blob was decoded from text with one omitted
# base64 symbol, losing the last six trailing 0-bits. Reinsert it.
base=b+"A"
for i in range(len(base)+1):
    prefix,postfix=base[:i],base[i:]
    for ch in alphabet:
        candidate=base64.b64decode(prefix+ch+postfix+"==")
        if sha(candidate)==expected:
            source.write_bytes(candidate)
            from PIL import Image
            with Image.open(source) as im:
                im.load()
                assert im.size==(600,352)
                print("EXACT SOURCE LOGO RECOVERED, SHA256 VERIFIED",i,im.size)
            raise SystemExit(0)
raise SystemExit("STOP: Original user's logo could not be verified; not generating APK")
