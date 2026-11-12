# Lokale RisicoScan — taxateur / risk engineer

**Alleen lokaal.** Niets publiceren.

## Starten

```bash
cd lokaal-demo && ./START-LOKAAL.sh
# http://localhost:8765
```

Flask (zelfde data + GPT-foto):

```bash
python3 app.py
# POST /api/locatie  POST /api/risico  POST /api/upload
```

## Openbare APIs (live)

| API | Nut voor risicodeskundige |
|-----|---------------------------|
| **PDOK Locatieserver** | Adres, buurt, wijk, perceelkoppeling |
| **PDOK BAG WFS** | Bouwjaar, gebruiksdoel, oppervlakte, status |
| **CBS Wijken & Buurten 2024** | Blootstelling: dichtheid, bedrijven, WOZ, gas%, afstand brandweer/ziekenhuis |
| **Kadaster Kadastrale Kaart** | Perceelgrootte |
| **RWS NWB Wegen** | TS-bereikbaarheid / straatnet |
| **OSM + curated kazernes** | Opkomstschatting brandweer |
| **Open-Meteo** | Hoogte (overstromingsproxy), wind/neerslag 7 dagen |

## Nog schatting / niet open

- Bluswater/hydranten (geen betrouwbare open API)
- Officiële LIWO-overstromingskaarten (proxy via hoogte)
- Externe veiligheid BRZO/buisleidingen (later)

## Checklist

24 RiskWalk-onderwerpen + functie-specifieke vragen, score, taxatie, JSON-export.

## Screenshots

`screenshots/risicoscan-v2-*.png` en `/opt/cursor/artifacts/`
