# API Integratie Handleiding - Brandweer & Watervoorziening Agent

## 📡 Overzicht

Deze handleiding beschrijft hoe de Brandweer & Watervoorziening Agent kan worden geïntegreerd met externe APIs en diensten voor productie-gebruik.

## 🔑 Benodigde API Keys

### 1. Google Maps Platform API
Voor kaart weergave en route berekeningen:
```javascript
// In brandweer-watervoorziening.html, regel 9:
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY"></script>
```

**Benodigde diensten:**
- Maps JavaScript API
- Directions API
- Geocoding API
- Distance Matrix API

**Aanvragen:** https://console.cloud.google.com/

### 2. Nederlandse Overheid APIs

#### BAG API (Basisregistratie Adressen en Gebouwen)
```javascript
const BAG_API_BASE = 'https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2';
const BAG_API_KEY = 'YOUR_BAG_API_KEY';

async function getAddressCoordinates(postcode, huisnummer) {
    const response = await fetch(
        `${BAG_API_BASE}/adressen?postcode=${postcode}&huisnummer=${huisnummer}`,
        {
            headers: {
                'X-Api-Key': BAG_API_KEY,
                'Accept': 'application/json'
            }
        }
    );
    const data = await response.json();
    return data._embedded.adressen[0].geometrie;
}
```

**Documentatie:** https://www.kadaster.nl/zakelijk/producten/adressen-en-gebouwen/bag-api

## 🚒 Brandweer Data APIs

### 1. Brandweer Nederland API

```javascript
const BRANDWEER_API_BASE = 'https://api.brandweer.nl/v1';
const BRANDWEER_API_KEY = 'YOUR_BRANDWEER_API_KEY';

async function getNearestFireStation(lat, lon) {
    const response = await fetch(
        `${BRANDWEER_API_BASE}/kazernes/nearest?lat=${lat}&lon=${lon}&radius=10000`,
        {
            headers: {
                'Authorization': `Bearer ${BRANDWEER_API_KEY}`,
                'Content-Type': 'application/json'
            }
        }
    );
    
    const data = await response.json();
    return {
        name: data.naam,
        type: data.type, // 'beroeps' of 'vrijwilligers'
        address: data.adres,
        coordinates: {
            lat: data.locatie.lat,
            lon: data.locatie.lon
        },
        equipment: data.materieel,
        personnel: data.personeel,
        responseTime24_7: data.permanenteBezetting
    };
}
```

### 2. OpenStreetMap Overpass API (Gratis alternatief)

```javascript
async function getFireStationsOSM(lat, lon, radius = 10000) {
    const query = `
        [out:json];
        (
            node["amenity"="fire_station"](around:${radius},${lat},${lon});
            way["amenity"="fire_station"](around:${radius},${lat},${lon});
        );
        out body;
        >;
        out skel qt;
    `;
    
    const response = await fetch('https://overpass-api.de/api/interpreter', {
        method: 'POST',
        body: query
    });
    
    const data = await response.json();
    return data.elements.map(element => ({
        name: element.tags.name || 'Onbekend',
        type: element.tags.operator?.includes('vrijwillig') ? 'vrijwilligers' : 'beroeps',
        lat: element.lat || element.center.lat,
        lon: element.lon || element.center.lon,
        address: element.tags['addr:full'] || ''
    }));
}
```

## 💧 Watervoorziening APIs

### 1. Waternet API (Amsterdam)

```javascript
const WATERNET_API = 'https://api.waternet.nl/v1';

async function getWaterSources(lat, lon, radius = 500) {
    const response = await fetch(
        `${WATERNET_API}/blusmiddelen?lat=${lat}&lon=${lon}&radius=${radius}`,
        {
            headers: {
                'X-API-Key': 'YOUR_WATERNET_API_KEY'
            }
        }
    );
    
    const data = await response.json();
    return data.blusmiddelen.map(source => ({
        type: source.type, // 'brandkraan', 'open_water', 'bluswaterriool'
        location: source.omschrijving,
        distance: source.afstand,
        capacity: source.capaciteit,
        accessibility: source.toegankelijkheid,
        coordinates: {
            lat: source.locatie.lat,
            lon: source.locatie.lon
        }
    }));
}
```

### 2. PDOK Water API

```javascript
async function getOpenWaterPDOK(lat, lon, radius = 1000) {
    const bbox = calculateBoundingBox(lat, lon, radius);
    const wfsUrl = `https://service.pdok.nl/rws/watersysteem/wfs/v1_0?
        service=WFS&
        version=2.0.0&
        request=GetFeature&
        typeName=watersysteem:oppervlaktewaterlichaam&
        bbox=${bbox}&
        outputFormat=application/json`;
    
    const response = await fetch(wfsUrl);
    const data = await response.json();
    
    return data.features.map(feature => ({
        type: 'Open water',
        name: feature.properties.naam,
        category: feature.properties.categorie,
        geometry: feature.geometry
    }));
}

function calculateBoundingBox(lat, lon, radiusMeters) {
    const latDiff = radiusMeters / 111320;
    const lonDiff = radiusMeters / (111320 * Math.cos(lat * Math.PI / 180));
    
    return [
        lon - lonDiff,
        lat - latDiff,
        lon + lonDiff,
        lat + latDiff
    ].join(',');
}
```

## 🗺️ Route Berekening APIs

### Google Maps Directions API

```javascript
async function calculateDrivingDistance(origin, destination) {
    const service = new google.maps.DirectionsService();
    
    return new Promise((resolve, reject) => {
        service.route({
            origin: new google.maps.LatLng(origin.lat, origin.lon),
            destination: new google.maps.LatLng(destination.lat, destination.lon),
            travelMode: google.maps.TravelMode.DRIVING,
            drivingOptions: {
                departureTime: new Date(),
                trafficModel: 'optimistic'
            }
        }, (result, status) => {
            if (status === 'OK') {
                const route = result.routes[0].legs[0];
                resolve({
                    distance: route.distance.value / 1000, // in km
                    duration: Math.ceil(route.duration.value / 60), // in minuten
                    route: result.routes[0].overview_path
                });
            } else {
                reject(status);
            }
        });
    });
}
```

### OpenRouteService (Gratis alternatief)

```javascript
const ORS_API_KEY = 'YOUR_OPENROUTESERVICE_API_KEY';

async function calculateRouteORS(origin, destination) {
    const response = await fetch('https://api.openrouteservice.org/v2/directions/driving-car', {
        method: 'POST',
        headers: {
            'Authorization': ORS_API_KEY,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            coordinates: [
                [origin.lon, origin.lat],
                [destination.lon, destination.lat]
            ],
            preference: 'fastest'
        })
    });
    
    const data = await response.json();
    const route = data.routes[0];
    
    return {
        distance: route.summary.distance / 1000, // in km
        duration: Math.ceil(route.summary.duration / 60), // in minuten
        geometry: route.geometry
    };
}
```

## 🔄 Agent-to-Agent Communicatie

### Method 1: URL Parameters
```javascript
// Agent A stuurt data naar brandweer agent
function sendToBrandweerAgent(postcode, huisnummer) {
    window.location.href = `brandweer-watervoorziening.html?postcode=${postcode}&huisnummer=${huisnummer}`;
}
```

### Method 2: LocalStorage
```javascript
// Agent A opslaan
const locationData = {
    postcode: "1012 JS",
    huisnummer: "45",
    straatnaam: "Damstraat",
    plaats: "Amsterdam",
    timestamp: Date.now()
};
localStorage.setItem('locationDataForBrandweer', JSON.stringify(locationData));

// Brandweer agent ophalen
const data = JSON.parse(localStorage.getItem('locationDataForBrandweer'));
if (data) {
    document.getElementById('postcode').value = data.postcode;
    document.getElementById('huisnummer').value = data.huisnummer;
    analyzeLocation();
}
```

### Method 3: PostMessage API (Cross-window)
```javascript
// Agent A
const brandweerWindow = window.open('brandweer-watervoorziening.html');
brandweerWindow.postMessage({
    type: 'LOCATION_DATA',
    data: {
        postcode: "1012 JS",
        huisnummer: "45"
    }
}, '*');

// Brandweer agent
window.addEventListener('message', (event) => {
    if (event.data.type === 'LOCATION_DATA') {
        const { postcode, huisnummer } = event.data.data;
        document.getElementById('postcode').value = postcode;
        document.getElementById('huisnummer').value = huisnummer;
        analyzeLocation();
    }
});
```

### Method 4: REST API (Backend)
```javascript
// Server-side endpoint
app.post('/api/brandweer/analyze', async (req, res) => {
    const { postcode, huisnummer } = req.body;
    
    // Haal coordinaten op
    const coords = await getAddressCoordinates(postcode, huisnummer);
    
    // Zoek dichtstbijzijnde brandweerkazerne
    const station = await getNearestFireStation(coords.lat, coords.lon);
    
    // Bereken route
    const route = await calculateDrivingDistance(coords, station.coordinates);
    
    // Zoek waterbronnen
    const waterSources = await getWaterSources(coords.lat, coords.lon);
    
    res.json({
        location: { postcode, huisnummer, coords },
        fireStation: station,
        route: route,
        waterSources: waterSources
    });
});

// Client-side
async function analyzeLocationAPI(postcode, huisnummer) {
    const response = await fetch('/api/brandweer/analyze', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ postcode, huisnummer })
    });
    
    const data = await response.json();
    displayResults(data);
}
```

## 🔧 Implementatie Voorbeeld

Volledige productie-klare implementatie van `performAnalysis`:

```javascript
async function performAnalysis(postcode, huisnummer) {
    try {
        // 1. Geocodeer het adres
        const coords = await getAddressCoordinates(postcode, huisnummer);
        
        // 2. Zoek brandweerkazernes
        const stations = await getNearestFireStation(coords.lat, coords.lon);
        
        // 3. Bereken routes voor alle kazernes
        const stationsWithRoutes = await Promise.all(
            stations.map(async (station) => {
                const route = await calculateDrivingDistance(coords, station.coordinates);
                return {
                    ...station,
                    distance: route.distance,
                    duration: route.duration
                };
            })
        );
        
        // 4. Sorteer op afstand
        stationsWithRoutes.sort((a, b) => a.distance - b.distance);
        const nearest = stationsWithRoutes[0];
        
        // 5. Zoek waterbronnen
        const waterSources = await getWaterSources(coords.lat, coords.lon);
        
        // 6. Update UI
        displayResults({
            location: { postcode, huisnummer, coords },
            fireStation: nearest,
            allStations: stationsWithRoutes,
            waterSources: waterSources
        });
        
    } catch (error) {
        console.error('Fout bij analyseren:', error);
        alert('Er is een fout opgetreden bij het ophalen van de gegevens.');
    }
}
```

## 📊 Data Caching

Voor betere performance:

```javascript
const CACHE_DURATION = 1000 * 60 * 60; // 1 uur

class DataCache {
    constructor() {
        this.cache = new Map();
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
        
        if (Date.now() - item.timestamp > CACHE_DURATION) {
            this.cache.delete(key);
            return null;
        }
        
        return item.value;
    }
}

const cache = new DataCache();

async function getCachedFireStations(lat, lon) {
    const key = `stations_${lat}_${lon}`;
    const cached = cache.get(key);
    
    if (cached) {
        return cached;
    }
    
    const stations = await getNearestFireStation(lat, lon);
    cache.set(key, stations);
    return stations;
}
```

## 🔐 Security Best Practices

1. **API Keys**: Bewaar nooit API keys in frontend code. Gebruik een backend proxy.
2. **Rate Limiting**: Implementeer rate limiting om kosten te beheersen.
3. **Input Validatie**: Valideer altijd postcode en huisnummer formaat.
4. **HTTPS**: Gebruik alleen HTTPS verbindingen.
5. **CORS**: Configureer CORS correct voor API requests.

## 📝 Testing

Test de integratie met mock data:

```javascript
// Mock mode voor development
const MOCK_MODE = true;

async function getNearestFireStation(lat, lon) {
    if (MOCK_MODE) {
        return {
            name: "Test Kazerne",
            type: "beroeps",
            distance: 2.5,
            duration: 6
        };
    }
    
    // Echte API call
    return await fetchRealFireStationData(lat, lon);
}
```

## 📞 Support & Resources

- **BAG API Docs**: https://www.kadaster.nl/zakelijk/producten/adressen-en-gebouwen/bag-api
- **PDOK Services**: https://www.pdok.nl/
- **OpenStreetMap**: https://www.openstreetmap.org/
- **Google Maps Platform**: https://developers.google.com/maps
- **OpenRouteService**: https://openrouteservice.org/

## 🚀 Deployment Checklist

- [ ] API keys geregistreerd en geconfigureerd
- [ ] Backend proxy geïmplementeerd voor API security
- [ ] Rate limiting geactiveerd
- [ ] Caching geïmplementeerd
- [ ] Error handling toegevoegd
- [ ] Monitoring en logging geconfigureerd
- [ ] GDPR compliance gecontroleerd
- [ ] Performance testing uitgevoerd
- [ ] Backup strategie geïmplementeerd
