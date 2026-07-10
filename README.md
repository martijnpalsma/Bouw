# Building Data Agent

Een complete en gespecialiseerde Python agent voor het ophalen van open data voor gebouwtaxatie en gebouwinspectie.

## 🚀 Quick Start

```bash
# Installeer dependencies
pip install -r requirements.txt

# Kopieer environment configuratie
cp .env.example .env

# Run een voorbeeld
python examples/test_mock_data.py
```

## 📦 Installatie

### Via pip (development mode)

```bash
pip install -e .
```

### Via setup.py

```bash
python setup.py install
```

## 💡 Gebruik

### Command-line Interface

```bash
# Haal gebouwdata op
python cli.py fetch 1071DJ 1 --format pretty

# Genereer taxatierapport
python cli.py report 1071DJ 1 --output rapport.pdf --format pdf

# Batch processing
python cli.py batch adressen.csv --output resultaten.json

# Start API server
python cli.py api --host 0.0.0.0 --port 8000
```

### Python API

```python
from building_data_agent import BuildingDataAgent

# Initialiseer agent
agent = BuildingDataAgent()

# Haal gebouwdata op
result = agent.get_building_data(
    postcode="1071DJ",
    huisnummer=1
)

# Genereer rapport
report = agent.generate_valuation_report(result)
report.save_pdf("rapport.pdf")
```

### REST API

```bash
# Start server
python examples/api_server.py

# Of via CLI
python cli.py api

# Gebruik de API
curl -X POST http://localhost:8000/api/v1/building-data \
  -H "Content-Type: application/json" \
  -d '{"postcode": "1071DJ", "huisnummer": 1}'
```

## 📚 Voorbeelden

Zie de `examples/` directory voor volledige voorbeelden:
- `simple_example.py` - Basis gebruik
- `batch_example.py` - Batch processing
- `api_server.py` - API server
- `test_mock_data.py` - Testen met mock data

## 🧪 Tests

```bash
# Run tests
pytest tests/ -v

# Met coverage
pytest tests/ --cov=building_data_agent --cov-report=html
```

## 📖 Documentatie

Voor volledige documentatie, zie [README_DATA_AGENT.md](README_DATA_AGENT.md)

## 🔧 Configuratie

Alle configuratie via environment variabelen (zie `.env.example`)

## 📄 Licentie

MIT License
