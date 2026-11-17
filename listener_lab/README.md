# Soukromý test počítadla pro Android

Tento adresář je oddělený pokus. Nic nemění v MediaCP ani v běžící stanici.
Aktuální produkční počítadlo v jiné větvi dál čte skutečné `connections`.

## Ovládání po přenesení souboru na VPS

Použijte Python 3.9+ a samostatný adresář, například
`/opt/radio-cesky-raj/listener_lab`. Skript udržuje vlastní soubor
`listener_lab_state.json`, který má při vytvoření práva `0600`.

```bash
python3 listener_lab.py set-peak 800
python3 listener_lab.py show
python3 listener_lab.py set-peak 2000 --from-date 2026-12-01 --ramp-days 14
```

První příkaz nastaví denní maximum od dnešního dne. Plánovaný příkaz zvýší
maximum postupně během 14 kalendářních dnů od 1. prosince. Datum i počet
jsou příklady; hodnoty lze později změnit stejným příkazem.

`publish` vytváří jeden statický JSON pro danou minutu:

```bash
python3 listener_lab.py publish --output /CESTA_K_TESTOVACIMU_HTTPS_WEBROOT/listeners.json
```

Výstupní cestu je nutné určit podle vašeho skutečného HTTPS webového serveru.
Soubor je určený jen pro soukromou testovací variantu aplikace. Spouštějte
`publish` jednou za minutu samostatnou cron úlohou; skript zapisuje atomicky
a při opakovaném spuštění v téže minutě vrací tentýž výsledek.

Skript načte veřejný MediaCP JSON, přičte skutečná připojení k testovací
křivce a nikdy nepřekročí nastavené denní maximum. Pokud stream hlásí
offline, zveřejní nulu. Při nedostupném zdroji publikuje `null`, nikoli
vymyšlenou hodnotu. Pole `test_mode: true` slouží aplikaci k rozpoznání
testovacích dat.

## Android

Větev `listener-lab` má vlastní workflow **RCR PRIVATE LISTENER LAB**.
Automatická testovací sestava bez `listener_url` čte pouze skutečný společný
počet `connections` z veřejného MediaCP JSON. Žádný počet neposlouchá ani
nevypočítává podle času telefonu. Po zpřístupnění statického JSON přes HTTPS
spusťte workflow ručně s parametrem `listener_url`. Takto sestavené telefony
načtou stejný testovací snímek z VPS. Krátký rozdíl v okamžiku obnovy je dán
sítí a desetisekundovým intervalem dotazů.

Artefakty jsou podepsané dočasným testovacím klíčem a nejsou distribuční
verzí pro Google Play.
