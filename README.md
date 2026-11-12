# Bouw Informatie Systeem - Agent Orchestration Platform

## 📋 Overzicht

Dit systeem biedt een complete agent orchestration platform waar je meerdere agents kunt beheren, koppelen en laten samenwerken. Het platform ondersteunt onbeperkt aantal agents die via gestandaardiseerde interfaces met elkaar communiceren.

## 🤖 Agent Orchestration Platform

### Platform Componenten

1. **Agent Platform Dashboard** (`agent-platform.html`)
   - Centrale hub voor agent management
   - Real-time monitoring en logging
   - Workflow executie en management
   - Agent registratie en configuratie
   - Performance metrics en statistieken

2. **Workflow Builder** (`agent-workflow-builder.html`)
   - Visuele workflow designer
   - Drag-and-drop interface
   - Agent verbindingen en data flow
   - Workflow validatie en testing
   - Import/export functionaliteit

3. **Agent Developer Guide** (`AGENT_DEVELOPER_GUIDE.md`)
   - Complete documentatie voor agent ontwikkeling
   - Best practices en design patterns
   - Code voorbeelden en templates
   - Testing en debugging strategieën
   - Performance optimalisatie tips

4. **Agent Template** (`agent-template.html`)
   - Ready-to-use agent template
   - Pre-configured communicatie methoden
   - Input validatie en error handling
   - Performance monitoring
   - Export functionaliteit

## 🚀 Geregistreerde Agents

### 1. Gebouw Formulier Agent
**Type**: Input Agent  
**Functie**: Verzamelt gebouwinformatie en constructiedetails  
**Outputs**: postcode, huisnummer, straatnaam, plaats, gebouwType

### 2. Brandweer & Watervoorziening Agent
**Type**: Analysis Agent  
**Functie**: Analyseert brandweerzorgen en watervoorziening  
**Inputs**: postcode, huisnummer  
**Outputs**: fireStation, distance, duration, waterSources

### 3. Bouw Informatie Systeem
**Type**: Output Agent  
**Functie**: Genereert overzichten en rapporten  
**Inputs**: gebouwData, brandweerData  
**Outputs**: rapport, pdf

### 4. AI Foto Analyse Agent
**Type**: AI Analysis Agent  
**Functie**: Analyseert gebouwfoto's met GPT-4 Vision voor constructie, materialen en isolatie  
**Inputs**: gebouwfoto (JPG, PNG, GIF, WebP)  
**Outputs**: constructie, materialen, isolatie, staat, bouwperiode, verduidelijkingsvragen  
**Backend**: Flask REST API met OpenAI GPT-4o integratie  
**Documentatie**: Zie [FOTO_ANALYSE_README.md](FOTO_ANALYSE_README.md), [QUICKSTART.md](QUICKSTART.md), [API_TESTING.md](API_TESTING.md)

## 🔄 Agent Communicatie

Het platform ondersteunt drie methoden voor agent-to-agent communicatie:

### Methode 1: URL Parameters
Eenvoudig voor simpele data overdracht.
```javascript
window.location.href = `next-agent.html?param1=value1&param2=value2`;
```

### Methode 2: LocalStorage
Voor complexere data structuren.
```javascript
localStorage.setItem('agentInput', JSON.stringify(data));
window.location.href = 'next-agent.html';
```

### Methode 3: PostMessage API
Voor real-time cross-window communicatie.
```javascript
targetWindow.postMessage({
    type: 'AGENT_DATA',
    payload: data
}, window.location.origin);
```

## 📁 Bestandsstructuur

```
/
├── RiskWalk/                           # Native iOS inspectie-app (SwiftUI)
│   ├── RiskWalk.xcodeproj
│   ├── RiskWalk/                       # App sources + privacy resources
│   ├── RiskWalkTests/
│   ├── README.md
│   └── PRIVACY_SECURITY.md
│
├── index.html                          # Hoofdpagina (web agents)
├── agent-platform.html                 # Agent dashboard
├── agent-workflow-builder.html         # Workflow builder
├── agent-template.html                 # Agent template
├── agent-integratie-voorbeeld.html    # Integratie voorbeelden
│
├── gebouw-formulier.html              # Gebouw formulier agent
├── brandweer-watervoorziening.html    # Brandweer agent
├── bouw-informatie-systeem.html       # Bouw systeem agent
├── foto-analyse.html                   # AI Foto analyse agent (frontend)
│
├── app.py                              # Flask backend voor foto analyse
├── requirements.txt                    # Python dependencies
├── start.sh / start.bat               # Startup scripts voor Flask API
├── uploads/                            # Upload directory voor foto's
│
├── README.md                           # Deze documentatie
├── FOTO_ANALYSE_README.md             # Foto analyse agent documentatie
├── QUICKSTART.md                       # Quick start voor foto analyse
├── API_TESTING.md                      # API testing guide
├── AGENT_DEVELOPER_GUIDE.md           # Developer guide
└── API_INTEGRATION.md                  # API integratie guide
```

### iOS-app (RiskWalk)

Open `RiskWalk/RiskWalk.xcodeproj` in Xcode. Privacy- en securitymaatregelen staan in `RiskWalk/PRIVACY_SECURITY.md`.

### AI Foto Analyse Agent

Deze agent vereist een Python backend:

```bash
# Installeer dependencies
pip install -r requirements.txt

# Configureer API key (optioneel - werkt ook in demo mode)
cp .env.example .env
# Bewerk .env en voeg OPENAI_API_KEY toe

# Start de server
./start.sh  # Linux/Mac
start.bat   # Windows

# Of direct:
python app.py
```

Server draait op `http://localhost:5000`. Zie [FOTO_ANALYSE_README.md](FOTO_ANALYSE_README.md) voor details.

## 🎯 Quick Start

### Voor Gebruikers

1. **Open het Agent Platform Dashboard**
   ```
   Open agent-platform.html in je browser
   ```

2. **Bekijk geregistreerde agents**
   - Zie alle beschikbare agents in de sidebar
   - Klik op een agent om deze te openen

3. **Start een workflow**
   - Klik op "Start Workflow" in het dashboard
   - Monitor de uitvoering in real-time

### Voor Developers

1. **Maak een nieuwe agent**
   ```bash
   cp agent-template.html mijn-nieuwe-agent.html
   ```

2. **Pas de agent aan**
   - Update `AGENT_CONFIG` met je agent details
   - Implementeer `performAnalysis()` functie
   - Pas UI aan naar behoefte

3. **Registreer de agent**
   - Open `agent-platform.html`
   - Klik "Nieuwe Agent Toevoegen"
   - Vul agent gegevens in

4. **Test de agent**
   - Open de agent direct
   - Test via workflow builder
   - Valideer agent communicatie

## 🛠️ Agent Development

### Nieuwe Agent Maken

```javascript
// 1. Definieer agent configuratie
const AGENT_CONFIG = {
    id: 'energie-agent',
    name: 'Energie Analyse Agent',
    version: '1.0.0',
    type: 'analysis'
};

// 2. Implementeer core functionaliteit
async function performAnalysis(input) {
    // Je analyse logica hier
    return results;
}

// 3. Setup communicatie
function setupAgentCommunication() {
    // URL params, LocalStorage, PostMessage
}
```

Zie `AGENT_DEVELOPER_GUIDE.md` voor complete documentatie.

## 🔗 Workflows Maken

### Via Workflow Builder

1. Open `agent-workflow-builder.html`
2. Sleep agents naar het canvas
3. Verbind agents door op ze te klikken
4. Configureer agent properties
5. Test en valideer de workflow
6. Exporteer of opslaan

### Via Code

```javascript
const workflow = {
    name: 'Mijn Workflow',
    nodes: [
        {
            id: 'node-1',
            agentId: 'gebouw-formulier',
            x: 100,
            y: 100
        },
        {
            id: 'node-2',
            agentId: 'brandweer-agent',
            x: 400,
            y: 100
        }
    ],
    connections: [
        {
            from: 'node-1',
            to: 'node-2'
        }
    ]
};
```

## 📊 Platform Features

### Agent Management
- ✅ Agent registratie en configuratie
- ✅ Status monitoring (active, idle, offline)
- ✅ Performance metrics
- ✅ Agent discovery

### Workflow Management
- ✅ Visuele workflow designer
- ✅ Drag-and-drop interface
- ✅ Workflow validatie
- ✅ Import/export workflows
- ✅ Workflow templates

### Monitoring & Logging
- ✅ Real-time execution logs
- ✅ Performance tracking
- ✅ Error reporting
- ✅ Activity timeline

### Data Management
- ✅ Gestandaardiseerde data formats
- ✅ Data validation
- ✅ Export functionaliteit
- ✅ Caching support

## 🎨 User Interface

### Dashboard Features
- **Statistics Cards**: Overzicht van agents, workflows en executions
- **Agent List**: Sidebar met alle geregistreerde agents
- **Workflow Canvas**: Visuele weergave van actieve workflows
- **Action Panel**: Knoppen voor workflow control
- **Activity Log**: Real-time logging van alle activiteiten

### Workflow Builder Features
- **Agent Palette**: Drag-and-drop agent selectie
- **Visual Canvas**: Grid-based workflow designer
- **Properties Panel**: Agent configuratie en instellingen
- **Toolbar**: Workflow management acties
- **Stats Bar**: Real-time workflow statistieken

## 🔧 Configuratie

### Agent Registry

Agents worden opgeslagen in LocalStorage:

```javascript
// Ophalen agents
const agents = JSON.parse(localStorage.getItem('registeredAgents') || '[]');

// Agent toevoegen
agents.push(newAgent);
localStorage.setItem('registeredAgents', JSON.stringify(agents));
```

### Workflow Storage

```javascript
// Workflow opslaan
const workflow = { nodes, connections };
localStorage.setItem('currentWorkflow', JSON.stringify(workflow));

// Workflow laden
const workflow = JSON.parse(localStorage.getItem('currentWorkflow'));
```

## 🚀 Deployment

### Lokaal Draaien

1. Clone de repository
2. Open `index.html` in een browser
3. Geen build process nodig voor web agents - pure HTML/CSS/JS
4. Voor AI Foto Analyse Agent: start Python backend (zie hierboven)

### Productie Deployment

Voor productie gebruik:
- Zet op een webserver (Apache, Nginx, etc.)
- Configureer HTTPS
- Implementeer API integraties (zie `API_INTEGRATION.md`)
- Setup monitoring en logging
- Configureer backup strategie
- Voor AI agent: deploy Flask app op productie server

## 📈 Performance

### Optimalisatie
- LocalStorage voor agent registry (snelle load times)
- Client-side processing (geen server roundtrips)
- Efficient DOM manipulation
- CSS animations voor smooth UX
- Lazy loading waar mogelijk

### Monitoring
```javascript
const monitor = new PerformanceMonitor();
const marker = monitor.start('operation');
// ... your code ...
monitor.end(marker);
```

## 🔐 Security

### Best Practices
- Input validatie op alle agents
- XSS preventie via sanitization
- CSRF tokens voor forms
- Origin validatie bij PostMessage
- Geen sensitive data in LocalStorage
- API keys in environment variables (voor AI agent)
- Secure file upload validatie

## 📱 Browser Support

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

## 🤝 Contributing

### Nieuwe Agent Toevoegen

1. Fork de repository
2. Kopieer `agent-template.html`
3. Implementeer je agent
4. Test grondig
5. Documenteer functionaliteit
6. Submit pull request

### Bug Reports

Gebruik GitHub Issues met:
- Beschrijving van het probleem
- Steps to reproduce
- Expected vs actual behavior
- Browser/OS informatie
- Screenshots indien relevant

## 📚 Documentatie

- **README.md** - Deze file: Algemeen overzicht
- **AGENT_DEVELOPER_GUIDE.md** - Complete developer guide
- **API_INTEGRATION.md** - API integratie documentatie
- **FOTO_ANALYSE_README.md** - AI Foto Analyse Agent (volledig)
- **QUICKSTART.md** - Quick start guide voor foto analyse
- **API_TESTING.md** - API testing voorbeelden
- **agent-integratie-voorbeeld.html** - Live code voorbeelden

## 🎓 Tutorials

### Tutorial 1: Je Eerste Agent

1. Open `agent-template.html`
2. Pas `AGENT_CONFIG` aan
3. Implementeer `performAnalysis()`
4. Test lokaal
5. Registreer in platform

### Tutorial 2: Workflow Maken

1. Open workflow builder
2. Sleep "Gebouw Formulier" naar canvas
3. Sleep "Brandweer Agent" naar canvas
4. Sleep "Bouw Systeem" naar canvas
5. Verbind de agents
6. Save workflow
7. Test uitvoering

### Tutorial 3: Agents Koppelen

```javascript
// In agent A
function sendToAgentB(data) {
    localStorage.setItem('agentB-input', JSON.stringify(data));
    window.location.href = 'agent-b.html';
}

// In agent B
const input = JSON.parse(localStorage.getItem('agentB-input'));
processData(input);
```

### Tutorial 4: AI Foto Analyse Gebruiken

1. Start de Flask backend: `python app.py`
2. Open `foto-analyse.html`
3. Upload een gebouwfoto
4. Bekijk de analyse resultaten
5. Beantwoord verduidelijkingsvragen
6. Zie [QUICKSTART.md](QUICKSTART.md) voor details

## 🐛 Troubleshooting

### Agent Laadt Niet
- Check browser console voor errors
- Valideer agent URL in registry
- Check LocalStorage quota

### Workflow Werkt Niet
- Valideer workflow in builder
- Check agent connectivity
- Review activity logs

### Data Komt Niet Door
- Valideer data format
- Check communicatie methode
- Review agent inputs/outputs

### Foto Analyse Werkt Niet
- Check of Flask server draait op port 5000
- Controleer bestandsformaat (JPG, PNG, GIF, WebP)
- Verifieer bestandsgrootte (max 10MB)
- Zie [API_TESTING.md](API_TESTING.md) voor test procedures

## 📞 Support

- **Documentatie**: Zie `AGENT_DEVELOPER_GUIDE.md`
- **Voorbeelden**: `agent-integratie-voorbeeld.html`
- **Template**: `agent-template.html`
- **Foto Analyse**: `FOTO_ANALYSE_README.md`

## 🗺️ Roadmap

### v1.1 (Gepland)
- [ ] Real-time collaboration
- [ ] Agent versioning
- [ ] Workflow scheduling
- [ ] Advanced analytics
- [ ] Batch foto upload voor AI agent

### v1.2 (Gepland)
- [ ] REST API backend
- [ ] Database integratie
- [ ] User authentication
- [ ] Multi-tenant support
- [ ] PDF export van foto analyses

### v2.0 (Toekomst)
- [ ] AI-powered agent recommendations
- [ ] Auto-scaling workflows
- [ ] Distributed execution
- [ ] Plugin system
- [ ] 3D model reconstructie uit foto's

## 📄 Licentie

© 2025-2026 Bouw Informatie Systeem - Alle rechten voorbehouden

## 👥 Contributors

- Development Team
- Open source contributors

## 📅 Changelog

### v1.1.0 (2026-08-16)
- ✨ AI Foto Analyse Agent toegevoegd
- ✨ Flask REST API backend
- ✨ GPT-4 Vision integratie
- ✨ Interactieve verduidelijkingsvragen
- ✨ Complete documentatie (3 nieuwe docs)
- 🔧 Merged met Agent Platform

### v1.0.0 (2026-07-12)
- ✨ Initial release
- ✨ Agent Platform Dashboard
- ✨ Workflow Builder
- ✨ 3 Pre-built agents
- ✨ Complete documentation
- ✨ Agent template

---

**Built with ❤️ for the construction industry**
