# Rádio Český ráj – původní aplikace Flutter

**Důležité:** Tento repozitář obsahuje workflow pro sestavení **původní Flutter aplikace Rádio Rohozec**, která byla podle zadání upravena na **Rádio Český ráj**. Nejedná se o jednoduchý náhradní Java přehrávač.

Zdrojový soubor **RADIO_CESKY_RAJ_ANDROID.zip** je připravený v konverzaci ChatGPT. Pro první sestavení musí být nahraný do kořene tohoto repozitáře pod stejným jménem, bez rozbalování.

Jak nahrát archiv: otevřít [Upload files](https://github.com/portaljukebox-stack/radio-cesky-raj-android/upload/main), přetáhnout RADIO_CESKY_RAJ_ANDROID.zip, potvrdit **Commit changes**. Nahrání spustí **GitHub Actions → PUVODNI FLUTTER APLIKACE - APK**, který použije Flutter 3.7.12 kompatibilní se zdrojovým kódem.

Po úspěšném buildu se APK objeví v sekci Artifacts pod názvem **Radio_Cesky_Raj_PUVODNI_FLUTTER_APK**.

## Zachované původní funkce

- hlavní obrazovka s přehrávačem a stavy vysílání
- ovládání hlasitosti a informace o přehrávání (dle podpory streamu)
- časovač vypnutí a jeho vlastní obrazovka
- boční nabídka, sdílení, informace o rádiu a ochrana soukromí
- originální Flutter vzhled, obrázky, ikona, splash a písma

## Změněno pro Rádio Český ráj

Stream: `https://portal.juke-box.cz:2020/stream/radioceskyraj`

Oficiální web: `https://www.radioceskyraj.cz/`

Partner: `https://rajoviny.cz/`

**Nezaměňovat testovací APK za produkční distribuční verzi.** Původní Flutter projekt používá historické závislosti, proto je po prvním sestavení potřeba prověřit kompatibilitu s dnešními Android zařízeními, živý stream, stabilitu přehrávání, podpis a následně modernizovat Android SDK / Flutter pro Google Play.

Veřejný GitHub repozitář momentálně obsahuje postup sestavení, nikoliv ZIP zdrojové aplikace. Původní podpisový klíč a tajné údaje sem nenahrávejte.
