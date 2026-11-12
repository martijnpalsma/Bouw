# Lokale RisicoScan — volledig voor taxateur / risicodeskundige

**Alleen lokaal.** Niets wordt gepubliceerd.

## Starten

```bash
cd lokaal-demo
./START-LOKAAL.sh
```

- Computer: http://localhost:8765  
- iPhone/iPad (zelfde wifi): `http://JOUW-IP:8765`

Optioneel Flask-API (zelfde analyses + GPT-foto):

```bash
cd ..
python3 app.py
# POST /api/locatie  POST /api/risico  POST /api/upload
```

## Wat erin zit (noodzakelijk voor risicodeskundige)

### Live open data
| Bron | Wat |
|------|-----|
| **PDOK Locatieserver** | Adres, buurt, wijk, gemeente, waterschap, perceel |
| **PDOK BAG WFS** | Bouwjaar, status, gebruiksdoel, oppervlakte, # VBO’s |
| **OSM/Nominatim** | Brandweerkazernes in de buurt |
| **Curated NL-kazernes** | Aanvulling waar OSM dun is (o.a. Amsterdam centrum) |

### Schatting / inspectie
| Onderdeel | Status |
|-----------|--------|
| Bluswater / hydranten | Schatting + checklist (geen betrouwbare open hydrant-API) |
| Opkomsttijd | Berekend uit afstand + uitruk (beroeps/vrijwilligers) |
| GPT Vision foto | Optioneel via Flask + OpenAI key |

### RiskWalk-checklist (24 onderwerpen)
Bedrijfsactiviteiten, gebouwen, constructie, gevel/dak, compartimentering, elektra, verwarming, branddetectie, blusmiddelen, huishouding, roken/open vuur, accu’s/laden, gevaarlijke stoffen, machines, opslag, buitenopslag, inbraak, water, storm, bedrijfsschade, brandweer/repressie, ontruiming/BHV, dak/PV, sandwichpanelen.

Plus functie-specifieke vragen (horeca, hotel, zorg, warehouse, garage, …).

### Output
- Risicoscore + niveau  
- Taxatie-aandacht (premie-drivers)  
- Prioriteitsvragen + antwoorden → verfijning  
- JSON-export  

## Screenshots

Zie `screenshots/` en `/opt/cursor/artifacts/risicoscan-v2-*.png`.
