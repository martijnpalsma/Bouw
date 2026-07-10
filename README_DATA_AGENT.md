# Gebouwtaxatie en Inspectie Data Agent

## Overzicht

Een gespecialiseerde agent voor het ophalen van open data voor gebouwtaxatie en gebouwinspectie uit Nederlandse databronnen.

## Functies

### 1. BAG (Basisregistratie Adressen en Gebouwen)
- Adresgegevens ophalen
- Pand informatie (bouwjaar, oppervlakte, gebruiksdoel)
- Verblijfsobjecten
- Geometrie en locatie data

### 2. WOZ (Waardering Onroerende Zaken)
- WOZ-waardes opvragen
- Historische waarderingen
- Taxatiegegevens

### 3. Kadaster Open Data
- Eigendomsinformatie
- Perceelgegevens
- Kadastrale kaarten

### 4. RVO (Rijksdienst voor Ondernemend Nederland)
- Energielabels
- Duurzaamheidscertificaten
- EPA (Energie Prestatie Advies)

### 5. Omgevingsloket
- Vergunningen
- Bouwdossiers
- Inspectierapporten

## Installatie

```bash
pip install -r requirements.txt
```

## Configuratie

Kopieer `.env.example` naar `.env` en vul je API keys in:

```bash
cp .env.example .env
```

## Gebruik

### Basis Voorbeeld

```python
from building_data_agent import BuildingDataAgent

# Initialiseer de agent
agent = BuildingDataAgent()

# Zoek gebouwgegevens op adres
result = agent.get_building_data(
    postcode="1012JS",
    huisnummer=1,
    huisletter="A"
)

print(result.to_dict())
```

### Geavanceerd Gebruik

```python
from building_data_agent import BuildingDataAgent
from building_data_agent.models import AddressQuery

# Maak een query object
query = AddressQuery(
    postcode="1012JS",
    huisnummer=1,
    huisletter="A"
)

# Initialiseer agent met specifieke data sources
agent = BuildingDataAgent(
    enable_bag=True,
    enable_woz=True,
    enable_kadaster=True,
    enable_energielabel=True
)

# Haal alle data op
result = agent.fetch_all_data(query)

# Print resultaten per bron
print("BAG Data:", result.bag_data)
print("WOZ Data:", result.woz_data)
print("Kadaster Data:", result.kadaster_data)
print("Energielabel:", result.energielabel_data)

# Genereer taxatierapport
report = agent.generate_valuation_report(result)
report.save_pdf("taxatierapport.pdf")
```

### Batch Processing

```python
from building_data_agent import BuildingDataAgent
import pandas as pd

agent = BuildingDataAgent()

# Lees adressen uit CSV
addresses = pd.read_csv("adressen.csv")

# Verwerk batch
results = agent.batch_process(
    addresses,
    output_format="excel",
    output_file="resultaten.xlsx"
)
```

## API Endpoints

De agent biedt ook een REST API:

```bash
# Start de API server
python -m building_data_agent.api

# Of met uvicorn
uvicorn building_data_agent.api:app --reload
```

### API Voorbeelden

```bash
# Haal gebouwdata op
curl -X POST http://localhost:8000/api/v1/building-data \
  -H "Content-Type: application/json" \
  -d '{
    "postcode": "1012JS",
    "huisnummer": 1,
    "huisletter": "A"
  }'

# Haal alleen BAG data op
curl http://localhost:8000/api/v1/bag?postcode=1012JS&huisnummer=1

# Haal WOZ waarde op
curl http://localhost:8000/api/v1/woz?postcode=1012JS&huisnummer=1

# Haal energielabel op
curl http://localhost:8000/api/v1/energielabel?postcode=1012JS&huisnummer=1
```

## Data Bronnen

### BAG API
- **Basis URL**: https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2/
- **Documentatie**: https://www.kadaster.nl/zakelijk/producten/adressen-en-gebouwen/bag-api-individuele-bevragingen
- **Authenticatie**: API Key (optioneel voor bevragingen)

### Kadaster PDOK
- **Basis URL**: https://api.pdok.nl/
- **Documentatie**: https://www.pdok.nl/
- **Authenticatie**: Geen (open data)

### RVO Energielabel API
- **Basis URL**: https://public.ep-online.nl/
- **Documentatie**: https://www.ep-online.nl/
- **Authenticatie**: Geen (publieke data)

## Architectuur

```
building_data_agent/
├── __init__.py
├── agent.py                 # Main agent class
├── config.py               # Configuration management
├── models.py               # Data models
├── connectors/
│   ├── __init__.py
│   ├── base.py            # Base connector class
│   ├── bag.py             # BAG connector
│   ├── woz.py             # WOZ connector
│   ├── kadaster.py        # Kadaster connector
│   └── energielabel.py    # Energielabel connector
├── processors/
│   ├── __init__.py
│   ├── data_merger.py     # Merge data from multiple sources
│   └── validator.py       # Data validation
├── reports/
│   ├── __init__.py
│   ├── generator.py       # Report generation
│   └── templates/         # Report templates
├── api/
│   ├── __init__.py
│   ├── main.py           # FastAPI application
│   └── routes/           # API routes
└── utils/
    ├── __init__.py
    ├── cache.py          # Caching utilities
    └── logging.py        # Logging configuration
```

## Licentie

MIT License

## Bijdragen

Bijdragen zijn welkom! Zie CONTRIBUTING.md voor details.

## Contact

Voor vragen of ondersteuning, open een issue op GitHub.
