# Lokale RisicoScan — taxateur / risk engineer

**Regel:** alleen harde feiten als feit. Alles anders = **CONTROLEER** of **SCHATTING**.

## Starten (Mac/PC)

```bash
cd lokaal-demo && ./START-LOKAAL.sh
# http://localhost:8765
```

## Testen op iPhone (Safari)

1. Start de server op je Mac/PC (zelfde wifi als je iPhone).
2. Zoek je lokale IP:
   - Mac: Systeeminstellingen → Netwerk, of `ipconfig getifaddr en0`
   - Windows: `ipconfig` → IPv4-adres
3. Open op iPhone Safari: `http://JOUW-IP:8765`
4. Voeg toe aan beginscherm (Deel → Zet op beginscherm) voor app-achtig gebruik.

Native SwiftUI-app (Xcode vereist): map `FotoAnalyseApp/` — zie `FotoAnalyseApp/README.md`.

## Openbare APIs

| API | Zekerheid |
|-----|-----------|
| PDOK Locatieserver / BAG WFS | **FEIT** |
| CBS Wijken & Buurten | **FEIT** (buurt ≠ object) |
| Kadaster perceel | **FEIT** |
| OSM / curated kazerne + hemelsbrede afstand | **FEIT** afstand / naam |
| Opkomsttijd / risicoklasse | **SCHATTING** |
| NWB bereikbaarheid | **SCHATTING** — CONTROLEER |
| Open-Meteo hoogte / weer | **FEIT** metingen; overstromingslabel = **SCHATTING** |
| Bluswater / hydranten | **SCHATTING** — altijd CONTROLEER |

## Checklist

24 RiskWalk-onderwerpen. Status pas **FEIT** na jouw inspectie-antwoord.
