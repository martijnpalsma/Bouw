# Lokale RisicoScan — zo open je het nu

Dit is **alleen lokaal**. Niets wordt gepubliceerd naar een website.

## Op computer

```bash
cd lokaal-demo
./START-LOKAAL.sh
```

Open in browser: **http://localhost:8765**

Of dubbelklik `index.html`.

## Op iPhone / iPad (zelfde wifi)

1. Start `./START-LOKAAL.sh` op je computer.
2. Noteer het IP dat in de terminal staat (bijv. `192.168.1.42`).
3. Open op je telefoon: `http://JOUW-IP:8765`

## Wat zit erin

- Foto-upload (of demo zonder foto)
- Constructie / materialen / isolatie
- Brandweer: kazerne, opkomsttijd, materieel, watervoorziening
- Taxateur-checklist (RiskWalk-onderwerpen)
- Verduidelijkingsvragen zoals een risicodeskundige stelt

## Status van de “APIs”

| Bron | Status |
|------|--------|
| Brandweer opkomst / water | Demo-logica (zelfde als brandweer-agent) — **nog geen live landelijke API** |
| BAG / PDOK | Nog niet live gekoppeld |
| GPT-4 Vision | Alleen via `python app.py` + OpenAI key |
| Taxateur-checklist | Lokaal meegeleverd |

## Screenshots

Zie `screenshots/` in deze map.
