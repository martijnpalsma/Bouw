# 🏗️ Gebouw Foto Analyse Systeem

Een geavanceerd AI-powered systeem voor het analyseren van gebouwfoto's. Upload foto's van gebouwen en ontvang gedetailleerde analyses van constructie, materialen, isolatie en meer.

## ✨ Features

- 📸 **Foto Upload**: Sleep & drop of klik om gebouwfoto's te uploaden
- 🤖 **AI Analyse**: Gebruikt GPT-4 Vision voor geavanceerde beeldanalyse
- 🏗️ **Constructie Details**: Identificeert type gebouw, draagconstructie en verdiepingen
- 🧱 **Materiaal Detectie**: Herkent gevel-, dak-, kozijn- en andere bouwmaterialen
- 🌡️ **Isolatie Inschatting**: Analyseert isolatiematerialen en -methoden
- 📋 **Staat Beoordeling**: Beoordeelt de algemene staat en onderhoudsbehoeften
- 📅 **Bouwperiode**: Schat de bouwperiode op basis van architectuur
- ❓ **Interactieve Vragen**: AI stelt verduidelijkingsvragen voor betere analyse
- 💬 **Conversatie Context**: Verfijn analyses met aanvullende informatie

## 🚀 Installatie

### Vereisten

- Python 3.8 of hoger
- pip (Python package manager)
- OpenAI API key

### Stap 1: Clone de repository

```bash
git clone <repository-url>
cd <project-directory>
```

### Stap 2: Installeer dependencies

```bash
pip install -r requirements.txt
```

### Stap 3: Configureer environment variables

```bash
cp .env.example .env
```

Bewerk `.env` en voeg je OpenAI API key toe:

```env
OPENAI_API_KEY=sk-your-actual-api-key-here
```

### Stap 4: Start de applicatie

```bash
python app.py
```

De applicatie draait nu op `http://localhost:5000`

## 📖 Gebruik

### Web Interface

1. Open `http://localhost:5000/foto-analyse.html` in je browser
2. Upload een gebouwfoto via drag & drop of klik
3. Klik op "Analyseer Gebouw"
4. Bekijk de gedetailleerde analyse
5. Beantwoord eventuele verduidelijkingsvragen voor een verfijnde analyse

### API Endpoints

#### POST /api/upload
Upload een gebouwfoto voor analyse.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: 
  - `file`: Image file (JPG, PNG, GIF, WebP)

**Response:**
```json
{
  "success": true,
  "filename": "20260710_123456_building.jpg",
  "model": "gpt-4o",
  "timestamp": "2026-07-10T12:34:56",
  "analysis": {
    "constructie": {
      "type": "Woonhuis",
      "draagconstructie": "Traditioneel metselwerk",
      "verdiepingen": 2,
      "details": "..."
    },
    "materialen": {
      "gevel": ["Baksteen"],
      "dak": ["Keramische pannen"],
      "kozijnen": ["Kunststof"],
      "overig": ["..."]
    },
    "isolatie": {
      "geschat": ["Spouwmuurisolatie", "Dakisolatie"],
      "waarschijnlijkheid": "hoog",
      "aanbevelingen": ["..."]
    },
    "staat": {
      "algemeen": "Goed",
      "onderhoud": "Regulier onderhoud nodig",
      "aandachtspunten": ["..."]
    },
    "bouwperiode": {
      "geschat": "1990-2000",
      "indicatoren": ["Moderne kozijnen", "Architectuurstijl"]
    },
    "verduidelijkingsvragen": [
      {
        "vraag": "Wanneer is het gebouw voor het laatst gerenoveerd?",
        "reden": "Voor nauwkeurige inschatting van isolatiewaarden"
      }
    ],
    "conclusie": "...",
    "betrouwbaarheid": "hoog"
  }
}
```

#### POST /api/clarify
Beantwoord verduidelijkingsvragen en verfijn de analyse.

**Request:**
```json
{
  "filename": "20260710_123456_building.jpg",
  "answer": "Het gebouw is in 2015 gerenoveerd met nieuwe isolatie",
  "conversation_history": []
}
```

**Response:**
Bijgewerkte analyse met verfijnde informatie.

#### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "api_configured": true,
  "timestamp": "2026-07-10T12:34:56"
}
```

## 🔧 Configuratie

### Environment Variables

| Variable | Beschrijving | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key voor GPT-4 Vision | Verplicht |
| `PORT` | Poort waarop de server draait | 5000 |
| `FLASK_ENV` | Flask environment (development/production) | development |
| `MAX_FILE_SIZE` | Maximale bestandsgrootte in bytes | 10485760 (10MB) |
| `UPLOAD_FOLDER` | Map voor geüploade bestanden | uploads |

### Ondersteunde Bestandsformaten

- PNG (.png)
- JPEG (.jpg, .jpeg)
- GIF (.gif)
- WebP (.webp)

Maximum bestandsgrootte: 10MB

## 🏗️ Technische Architectuur

### Backend
- **Framework**: Flask 3.0
- **AI Model**: GPT-4o (GPT-4 with vision)
- **Image Processing**: Pillow
- **CORS**: Flask-CORS

### Frontend
- **HTML5/CSS3**: Moderne responsive interface
- **JavaScript**: Vanilla JS voor interactiviteit
- **Drag & Drop**: Native HTML5 API
- **Fetch API**: Voor asynchrone API calls

### Bestandsstructuur

```
.
├── app.py                          # Flask backend server
├── requirements.txt                # Python dependencies
├── .env.example                    # Environment configuratie template
├── README.md                       # Deze documentatie
├── index.html                      # Hoofdpagina
├── foto-analyse.html               # Foto analyse interface
├── gebouw-formulier.html          # Gebouw formulier
├── bouw-informatie-systeem.html   # Informatie systeem
└── uploads/                        # Upload directory (auto-created)
```

## 🔒 Beveiliging

- **Bestandsvalidatie**: Alleen toegestane bestandstypen
- **Grootte limiet**: Maximum 10MB per upload
- **Secure filenames**: Werkzeug secure_filename()
- **API Key**: Veilig opgeslagen in environment variables
- **CORS**: Configureerbaar per environment

## 🐛 Troubleshooting

### OpenAI API Key Error

Als je de foutmelding "OpenAI API key niet geconfigureerd" ziet:
1. Controleer of `.env` bestand bestaat
2. Verificeer dat `OPENAI_API_KEY` correct is ingesteld
3. Herstart de applicatie

### Upload Fails

- Controleer bestandsgrootte (max 10MB)
- Verifieer bestandsformaat (PNG, JPG, GIF, WebP)
- Check schrijfrechten voor `uploads/` directory

### Demo Mode

Zonder API key draait het systeem in demo mode met voorbeeldanalyses.

## 📊 Analyse Betrouwbaarheid

Het systeem geeft een betrouwbaarheidsindicatie:
- **Hoog**: Duidelijke foto's, goede zichtbaarheid
- **Middel**: Beperkte zichtbaarheid of complexe situaties
- **Laag**: Onduidelijke foto's of onvoldoende informatie

## 🔄 Updates en Onderhoud

### Dependencies updaten

```bash
pip install --upgrade -r requirements.txt
```

### Model upgrades

Het systeem gebruikt GPT-4o. Voor andere modellen, pas `model` parameter aan in `app.py`.

## 🤝 Bijdragen

Suggesties en verbeteringen zijn welkom! 

## 📝 Licentie

Copyright © 2026 Bouw Informatie Systeem

## 🆘 Support

Voor vragen of problemen, neem contact op via [support@voorbeeld.nl]

## 🌐 Integratie met Bestaande Systemen

Dit systeem integreert naadloos met:
- `gebouw-formulier.html`: Gebruik analyse resultaten om formulieren in te vullen
- `bouw-informatie-systeem.html`: Import analyses in het hoofdsysteem
- Export mogelijkheden naar PDF en Excel (toekomstige feature)

## 🎯 Roadmap

- [ ] Batch upload (meerdere foto's tegelijk)
- [ ] PDF export van analyses
- [ ] Database integratie
- [ ] Gebruikersaccounts en historie
- [ ] Vergelijking met bouwvoorschriften
- [ ] 3D model generatie
- [ ] Energie-efficiëntie scores

---

**Versie**: 1.0.0  
**Laatste update**: Juli 2026
