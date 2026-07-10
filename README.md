# Bouw Informatie Systeem - Brandweer & Watervoorziening Agent

## 📋 Overzicht

Dit systeem biedt een complete oplossing voor het analyseren van brandweerzorgen en watervoorziening op basis van locatie. De agent kan postcode ontvangen van andere agents en berekent rijafstand, beschikbaar materieel, type brandweerpost en open watervoorziening in de buurt.

## 🚒 Functies

### Brandweer Analyse
- **Dichtstbijzijnde brandweerpost**: Berekent de dichtstbijzijnde kazerne op basis van rijafstand
- **Type post**: Identificeert of het een beroeps- of vrijwilligerspost betreft
- **Opkomsttijden**: Berekent geschatte opkomsttijden voor verschillende eenheden
- **Beschikbaar materieel**: Toont welk materieel beschikbaar is bij de dichtstbijzijnde posten
- **Risicoklassificatie**: Bepaalt het risiconiveau op basis van afstand en bereikbaarheid

### Watervoorziening
- **Brandkranen**: Locatie en capaciteit van nabijgelegen brandkranen
- **Open water**: Identificeert open water (kanalen, vijvers) voor bluswater
- **Bluswaterriool**: Speciale bluswatervoorzieningen met hoge capaciteit
- **Toegankelijkheid**: Beoordeelt de toegankelijkheid van waterbronnen

### Integratie Mogelijkheden
- **Agent-to-agent communicatie**: Ontvangt postcode van andere agents
- **URL parameters**: `?postcode=1234AB&huisnummer=45`
- **JSON export**: Exporteert data voor gebruik in andere systemen
- **PDF rapportage**: Genereert professionele rapporten

## 🗂️ Bestanden

- `index.html` - Hoofdpagina van het systeem
- `brandweer-watervoorziening.html` - Brandweer & watervoorziening agent
- `gebouw-formulier.html` - Gebouw registratie formulier
- `bouw-informatie-systeem.html` - Bouw informatie overzicht
- `README.md` - Deze documentatie
- `API_INTEGRATION.md` - API integratie handleiding

## 🔧 Gebruik

### Handmatig gebruik
1. Open `brandweer-watervoorziening.html` in een browser
2. Voer postcode en huisnummer in
3. Klik op "Analyseer Locatie"
4. Bekijk de resultaten en genereer indien gewenst een PDF rapport

### Via URL parameters
```
brandweer-watervoorziening.html?postcode=1012JS&huisnummer=45
```

### Agent integratie
De agent kan data ontvangen via JavaScript:
```javascript
// Verstuur data naar de brandweer agent
const locationData = {
    postcode: "1012 JS",
    huisnummer: "45",
    straatnaam: "Damstraat",
    plaats: "Amsterdam"
};

// Via URL parameters
window.location.href = `brandweer-watervoorziening.html?postcode=${locationData.postcode}&huisnummer=${locationData.huisnummer}`;

// Of via localStorage voor complexere data
localStorage.setItem('brandweerAgentInput', JSON.stringify(locationData));
```

## 📊 Data Structuur

### Input Data
```json
{
  "postcode": "1012 JS",
  "huisnummer": "45",
  "straatnaam": "Damstraat",
  "plaats": "Amsterdam"
}
```

### Output Data
```json
{
  "location": {
    "postcode": "1012 JS",
    "huisnummer": "45",
    "coordinates": {
      "lat": 52.3702,
      "lon": 4.8952
    }
  },
  "fireStation": {
    "name": "Brandweer Kazerne Centrum",
    "type": "beroeps",
    "distance": 2.3,
    "duration": 5,
    "address": "Hoofdweg 100, Amsterdam",
    "equipment": [
      "Tankautospuit",
      "Hulpverleningsvoertuig",
      "Hoogwerker"
    ],
    "personnel": 24,
    "responseTime24_7": true
  },
  "waterSources": [
    {
      "type": "Brandkraan",
      "location": "Voor locatie",
      "distance": 15,
      "capacity": "60 m³/uur",
      "accessibility": "Goed"
    },
    {
      "type": "Open water (kanaal)",
      "location": "Zuidzijde, 200m",
      "distance": 200,
      "capacity": "Onbeperkt",
      "accessibility": "Goed - Vlakke oever"
    }
  ],
  "timestamp": "2026-07-10T21:10:00.000Z"
}
```

## 🔌 API Integratie

Voor productie-omgevingen zie `API_INTEGRATION.md` voor:
- Nederlandse Brandweer APIs
- Geocoding services
- Route berekening APIs
- Waterkaart integraties

## 🎨 Technologie

- **Frontend**: Pure HTML5, CSS3, JavaScript (ES6+)
- **PDF Generatie**: jsPDF met autoTable plugin
- **Styling**: Responsive design met CSS Grid en Flexbox
- **Compatibiliteit**: Moderne browsers (Chrome, Firefox, Safari, Edge)

## 📱 Responsive Design

Het systeem is volledig responsive en werkt op:
- Desktop computers
- Tablets
- Smartphones

## 🔐 Security & Privacy

- Alle berekeningen gebeuren client-side
- Geen persoonlijke data wordt opgeslagen zonder toestemming
- Export functionaliteit is optioneel
- Data blijft lokaal tenzij expliciet verzonden

## 🚀 Toekomstige Uitbreidingen

- Real-time data van brandweer APIs
- Live kaart integratie met Google Maps / OpenStreetMap
- Automatische updates van brandweerpost informatie
- Integratie met BAG (Basisregistratie Adressen en Gebouwen)
- WebSocket verbinding voor real-time agent communicatie
- Machine learning voor risico-voorspelling

## 📞 Support

Voor vragen of problemen, zie de technische documentatie of neem contact op met het ontwikkelteam.

## 📄 Licentie

© 2025-2026 Bouw Informatie Systeem - Alle rechten voorbehouden
