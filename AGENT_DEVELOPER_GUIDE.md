# Agent Developer Guide

## 📘 Overzicht

Deze guide legt uit hoe je nieuwe agents kunt bouwen en toevoegen aan het Agent Orchestration Platform. Het platform ondersteunt onbeperkt aantal agents die met elkaar kunnen communiceren via gestandaardiseerde interfaces.

## 🏗️ Agent Architectuur

### Agent Types

Het platform ondersteunt verschillende agent types:

1. **Input Agents** - Verzamelen data van gebruikers of externe bronnen
2. **Processing Agents** - Verwerken en transformeren data
3. **Analysis Agents** - Analyseren data en genereren inzichten
4. **Output Agents** - Presenteren resultaten of exporteren data
5. **Integration Agents** - Integreren met externe services/APIs

### Agent Structuur

Elke agent moet de volgende structuur hebben:

```javascript
{
    id: 'unique-agent-id',              // Unieke identifier
    name: 'Agent Naam',                 // Menselijke naam
    icon: '🤖',                         // Emoji icoon
    type: 'analysis',                   // Agent type
    description: 'Beschrijving...',     // Wat doet de agent
    url: 'agent-naam.html',            // URL/endpoint
    status: 'active',                   // Status: active, idle, offline
    inputs: ['param1', 'param2'],       // Input parameters
    outputs: ['result1', 'result2']     // Output parameters
}
```

## 🚀 Nieuwe Agent Maken

### Stap 1: HTML Basis Template

Maak een nieuwe HTML file voor je agent:

```html
<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mijn Agent Naam</title>
    <style>
        /* Gebruik consistent styling met andere agents */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding-top: 80px;
        }

        /* Voeg je eigen styles toe */
    </style>
</head>
<body>
    <!-- Header navigatie -->
    <header class="header-nav">
        <!-- Navigatie zoals in andere agents -->
    </header>

    <!-- Agent content -->
    <div class="container">
        <!-- Je agent UI hier -->
    </div>

    <script>
        // Agent logica hier
    </script>
</body>
</html>
```

### Stap 2: Agent Communicatie Implementeren

Implementeer de drie communicatie methoden:

#### Methode 1: URL Parameters

```javascript
// Ontvang parameters
document.addEventListener('DOMContentLoaded', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const param1 = urlParams.get('param1');
    const param2 = urlParams.get('param2');
    
    if (param1 && param2) {
        processData(param1, param2);
    }
});

// Verstuur naar andere agent
function sendToNextAgent(data) {
    const url = `next-agent.html?param1=${encodeURIComponent(data.param1)}`;
    window.location.href = url;
}
```

#### Methode 2: LocalStorage

```javascript
// Ontvang data
const storedData = localStorage.getItem('myAgentInput');
if (storedData) {
    const data = JSON.parse(storedData);
    processData(data);
    localStorage.removeItem('myAgentInput'); // Cleanup
}

// Verstuur data
function sendToNextAgent(data) {
    localStorage.setItem('nextAgentInput', JSON.stringify(data));
    window.location.href = 'next-agent.html';
}
```

#### Methode 3: PostMessage API

```javascript
// Ontvang data
window.addEventListener('message', (event) => {
    // Valideer origin in productie!
    if (event.data.type === 'AGENT_DATA') {
        processData(event.data.payload);
    }
});

// Verstuur data
function sendToNextAgent(data) {
    const targetWindow = window.open('next-agent.html');
    setTimeout(() => {
        targetWindow.postMessage({
            type: 'AGENT_DATA',
            payload: data
        }, window.location.origin);
    }, 1000);
}
```

### Stap 3: Data Standaardisatie

Gebruik een gestandaardiseerd data formaat:

```javascript
const agentOutput = {
    agentId: 'my-agent',
    timestamp: new Date().toISOString(),
    success: true,
    data: {
        // Je agent output data
        result1: 'value1',
        result2: 'value2'
    },
    metadata: {
        executionTime: 123,
        version: '1.0'
    },
    error: null
};
```

### Stap 4: Error Handling

Implementeer robuuste error handling:

```javascript
async function processData(input) {
    try {
        // Valideer input
        if (!validateInput(input)) {
            throw new Error('Ongeldige input parameters');
        }
        
        // Verwerk data
        const result = await performAnalysis(input);
        
        // Return resultaat
        return {
            success: true,
            data: result,
            error: null
        };
        
    } catch (error) {
        console.error('Agent error:', error);
        
        return {
            success: false,
            data: null,
            error: error.message
        };
    }
}

function validateInput(input) {
    // Implementeer validatie logica
    return input && typeof input === 'object';
}
```

## 📝 Agent Registreren

### Via UI

1. Open `agent-platform.html`
2. Klik op "Nieuwe Agent Toevoegen"
3. Vul de gegevens in:
   - Agent Naam
   - Icoon (emoji)
   - Type
   - Beschrijving
   - URL/Endpoint
   - Input Parameters
   - Output Parameters
4. Klik op "Agent Opslaan"

### Via Code

```javascript
// Registreer agent programmatisch
const newAgent = {
    id: 'my-new-agent',
    name: 'Mijn Nieuwe Agent',
    icon: '⚡',
    type: 'analysis',
    description: 'Deze agent doet analyse op energie gegevens',
    url: 'energie-agent.html',
    status: 'active',
    inputs: ['gebouwId', 'periode'],
    outputs: ['energieVerbruik', 'kosten', 'co2']
};

// Ophalen huidige agents
let agents = JSON.parse(localStorage.getItem('registeredAgents') || '[]');

// Toevoegen nieuwe agent
agents.push(newAgent);

// Opslaan
localStorage.setItem('registeredAgents', JSON.stringify(agents));

console.log('✅ Agent geregistreerd!');
```

## 🔧 Best Practices

### 1. Input Validatie

```javascript
function validatePostcode(postcode) {
    const regex = /^[1-9][0-9]{3}\s?[A-Z]{2}$/i;
    return regex.test(postcode);
}

function sanitizeInput(input) {
    return String(input).trim().replace(/[<>]/g, '');
}
```

### 2. Loading States

```javascript
function showLoading() {
    document.getElementById('loading').style.display = 'block';
    document.getElementById('results').style.display = 'none';
}

function hideLoading() {
    document.getElementById('loading').style.display = 'none';
    document.getElementById('results').style.display = 'block';
}
```

### 3. Progress Feedback

```javascript
function updateProgress(step, total, message) {
    const percentage = (step / total) * 100;
    document.getElementById('progress-bar').style.width = percentage + '%';
    document.getElementById('progress-text').textContent = message;
}
```

### 4. Result Caching

```javascript
class ResultCache {
    constructor(expiryMinutes = 60) {
        this.cache = new Map();
        this.expiry = expiryMinutes * 60 * 1000;
    }
    
    set(key, value) {
        this.cache.set(key, {
            value: value,
            timestamp: Date.now()
        });
    }
    
    get(key) {
        const item = this.cache.get(key);
        if (!item) return null;
        
        if (Date.now() - item.timestamp > this.expiry) {
            this.cache.delete(key);
            return null;
        }
        
        return item.value;
    }
    
    clear() {
        this.cache.clear();
    }
}

const cache = new ResultCache(30); // 30 minuten
```

## 🧪 Testing

### Unit Tests

```javascript
// Test functies
function runTests() {
    console.log('🧪 Running agent tests...');
    
    // Test 1: Input validatie
    const test1 = validateInput({ postcode: '1234 AB', huisnummer: '45' });
    console.assert(test1 === true, 'Test 1 failed: Input validation');
    
    // Test 2: Data processing
    const test2Result = processData({ test: 'data' });
    console.assert(test2Result.success === true, 'Test 2 failed: Data processing');
    
    // Test 3: Output format
    const test3 = validateOutput(test2Result.data);
    console.assert(test3 === true, 'Test 3 failed: Output format');
    
    console.log('✅ All tests passed!');
}
```

### Integration Tests

```javascript
async function testAgentIntegration() {
    console.log('🔗 Testing agent integration...');
    
    // Simuleer data van vorige agent
    const inputData = {
        postcode: '1012 JS',
        huisnummer: '45'
    };
    
    // Verstuur naar agent
    localStorage.setItem('testAgentInput', JSON.stringify(inputData));
    
    // Wacht op resultaat
    setTimeout(() => {
        const result = localStorage.getItem('testAgentOutput');
        if (result) {
            console.log('✅ Integration test passed!');
            console.log('Result:', JSON.parse(result));
        } else {
            console.error('❌ Integration test failed!');
        }
    }, 2000);
}
```

## 📊 Performance

### Optimalisatie Tips

1. **Lazy Loading**: Laad grote data sets alleen wanneer nodig
2. **Debouncing**: Vermijd te veel API calls bij input changes
3. **Virtualization**: Gebruik virtual scrolling voor grote lijsten
4. **Web Workers**: Gebruik voor zware berekeningen
5. **Service Workers**: Implementeer voor offline support

### Performance Monitoring

```javascript
class PerformanceMonitor {
    constructor() {
        this.metrics = [];
    }
    
    start(operation) {
        return {
            operation: operation,
            startTime: performance.now()
        };
    }
    
    end(marker) {
        const duration = performance.now() - marker.startTime;
        this.metrics.push({
            operation: marker.operation,
            duration: duration,
            timestamp: new Date().toISOString()
        });
        
        console.log(`⏱️ ${marker.operation}: ${duration.toFixed(2)}ms`);
        return duration;
    }
    
    getMetrics() {
        return this.metrics;
    }
    
    getAverage(operation) {
        const ops = this.metrics.filter(m => m.operation === operation);
        if (ops.length === 0) return 0;
        
        const total = ops.reduce((sum, m) => sum + m.duration, 0);
        return total / ops.length;
    }
}

const monitor = new PerformanceMonitor();

// Gebruik
const marker = monitor.start('data-processing');
await processData(input);
monitor.end(marker);
```

## 🔐 Security

### Input Sanitization

```javascript
function sanitizeHTML(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function sanitizeURL(url) {
    try {
        const parsed = new URL(url);
        // Only allow http/https
        if (!['http:', 'https:'].includes(parsed.protocol)) {
            throw new Error('Invalid protocol');
        }
        return parsed.href;
    } catch {
        return null;
    }
}
```

### CSRF Protection

```javascript
function generateCSRFToken() {
    return Math.random().toString(36).substring(2, 15) +
           Math.random().toString(36).substring(2, 15);
}

function validateCSRFToken(token) {
    const storedToken = sessionStorage.getItem('csrf_token');
    return token === storedToken;
}
```

## 📦 Agent Voorbeeld: Energie Agent

Complete voorbeeld implementatie:

```javascript
// energie-agent.html
class EnergieAgent {
    constructor() {
        this.id = 'energie-agent';
        this.version = '1.0.0';
        this.cache = new Map();
    }
    
    async initialize() {
        console.log('🔌 Energie Agent geïnitialiseerd');
        this.setupEventListeners();
        this.loadSavedData();
    }
    
    setupEventListeners() {
        // URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('gebouwId')) {
            this.processFromURL(urlParams);
        }
        
        // LocalStorage
        const storedData = localStorage.getItem('energieAgentInput');
        if (storedData) {
            this.processFromStorage(JSON.parse(storedData));
        }
        
        // PostMessage
        window.addEventListener('message', (e) => this.processFromMessage(e));
    }
    
    async analyzeEnergie(gebouwId, periode) {
        const marker = performance.now();
        
        try {
            // Valideer input
            if (!this.validateInput(gebouwId, periode)) {
                throw new Error('Ongeldige input');
            }
            
            // Check cache
            const cacheKey = `${gebouwId}-${periode}`;
            if (this.cache.has(cacheKey)) {
                console.log('📦 Data uit cache');
                return this.cache.get(cacheKey);
            }
            
            // Simuleer analyse
            await this.delay(1000);
            
            const result = {
                gebouwId: gebouwId,
                periode: periode,
                verbruik: {
                    elektriciteit: Math.random() * 5000,
                    gas: Math.random() * 3000
                },
                kosten: {
                    totaal: Math.random() * 2000,
                    gemiddeldPerMaand: Math.random() * 200
                },
                co2Uitstoot: Math.random() * 1000,
                advies: this.generateAdvies()
            };
            
            // Cache resultaat
            this.cache.set(cacheKey, result);
            
            const duration = performance.now() - marker;
            console.log(`⚡ Analyse voltooid in ${duration.toFixed(2)}ms`);
            
            return {
                success: true,
                data: result,
                metadata: {
                    executionTime: duration,
                    agentId: this.id,
                    version: this.version
                }
            };
            
        } catch (error) {
            console.error('❌ Analyse fout:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }
    
    validateInput(gebouwId, periode) {
        return gebouwId && periode && periode.match(/^\d{4}-\d{2}$/);
    }
    
    generateAdvies() {
        const adviezen = [
            'Overweeg LED verlichting',
            'Verbeter isolatie',
            'Installeer zonnepanelen',
            'Optimaliseer verwarmingssysteem'
        ];
        return adviezen[Math.floor(Math.random() * adviezen.length)];
    }
    
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Initialiseer agent
const energieAgent = new EnergieAgent();
document.addEventListener('DOMContentLoaded', () => energieAgent.initialize());
```

## 📚 Resources

- [Agent Platform Dashboard](agent-platform.html)
- [Workflow Builder](agent-workflow-builder.html)
- [API Integration Guide](API_INTEGRATION.md)
- [Agent Integratie Voorbeelden](agent-integratie-voorbeeld.html)

## 🤝 Bijdragen

Wil je een nieuwe agent toevoegen aan het platform?

1. Volg deze guide
2. Test je agent grondig
3. Documenteer de functionaliteit
4. Registreer de agent in het platform
5. Deel je agent met het team

## 📞 Support

Voor vragen over agent ontwikkeling:
- Bekijk de voorbeelden in de repository
- Raadpleeg de API documentatie
- Test met de integratie voorbeelden

---

**Laatst bijgewerkt**: 2026-07-12  
**Versie**: 1.0.0
