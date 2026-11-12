# 🧪 API Testing Gids

Deze gids toont hoe je de Gebouw Foto Analyse API kunt testen met verschillende tools.

## API Endpoints Overzicht

| Endpoint | Methode | Beschrijving |
|----------|---------|--------------|
| `/api/health` | GET | Health check en status |
| `/api/upload` | POST | Upload en analyseer foto |
| `/api/clarify` | POST | Beantwoord verduidelijkingsvragen |

## 1. Health Check Test

### Met curl

```bash
curl http://localhost:5000/api/health
```

**Verwachte response:**
```json
{
    "status": "healthy",
    "api_configured": false,
    "timestamp": "2026-07-10T12:34:56"
}
```

### Met Python

```python
import requests

response = requests.get('http://localhost:5000/api/health')
print(response.json())
```

### Met JavaScript/Browser Console

```javascript
fetch('http://localhost:5000/api/health')
    .then(r => r.json())
    .then(data => console.log(data));
```

## 2. Photo Upload Test

### Met curl

```bash
# Upload een foto
curl -X POST \
  -F "file=@/path/to/building.jpg" \
  http://localhost:5000/api/upload \
  -o response.json

# Bekijk het resultaat
cat response.json | python3 -m json.tool
```

### Met Python

```python
import requests

# Upload foto
with open('building.jpg', 'rb') as f:
    files = {'file': f}
    response = requests.post(
        'http://localhost:5000/api/upload',
        files=files
    )

# Print resultaat
import json
print(json.dumps(response.json(), indent=2))
```

### Met Postman

1. Selecteer `POST` methode
2. URL: `http://localhost:5000/api/upload`
3. Ga naar "Body" tab
4. Selecteer "form-data"
5. Voeg key "file" toe, type "File"
6. Upload een gebouwfoto
7. Klik "Send"

**Verwachte response:**
```json
{
  "success": true,
  "filename": "20260710_123456_building.jpg",
  "model": "gpt-4o",
  "timestamp": "2026-07-10T12:34:56.789",
  "analysis": {
    "constructie": {
      "type": "Woonhuis",
      "draagconstructie": "Traditioneel metselwerk",
      "verdiepingen": 2,
      "details": "Vrijstaand woonhuis met zadeldak"
    },
    "materialen": {
      "gevel": ["Baksteen"],
      "dak": ["Keramische pannen"],
      "kozijnen": ["Kunststof"],
      "overig": ["Betonnen fundering"]
    },
    "isolatie": {
      "geschat": ["Spouwmuurisolatie", "Dakisolatie"],
      "waarschijnlijkheid": "hoog",
      "aanbevelingen": [
        "Overweeg vloerisolatie",
        "Check isolatiekwaliteit kozijnen"
      ]
    },
    "staat": {
      "algemeen": "Goed",
      "onderhoud": "Regulier onderhoud aanbevolen",
      "aandachtspunten": [
        "Voegwerk controleren",
        "Dakgoten schoonmaken"
      ]
    },
    "bouwperiode": {
      "geschat": "1990-2000",
      "indicatoren": [
        "Moderne kozijnen",
        "Architectuurstijl jaren '90"
      ]
    },
    "verduidelijkingsvragen": [
      {
        "vraag": "Wanneer is het gebouw voor het laatst gerenoveerd?",
        "reden": "Voor nauwkeurige inschatting van isolatiewaarden"
      },
      {
        "vraag": "Zijn er foto's van de binnenkant beschikbaar?",
        "reden": "Voor betere beoordeling van constructie en afwerking"
      }
    ],
    "conclusie": "Modern woonhuis uit jaren '90 in goede staat met waarschijnlijk voldoende isolatie",
    "betrouwbaarheid": "hoog"
  }
}
```

## 3. Clarification Test

### Met curl

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "filename": "20260710_123456_building.jpg",
    "answer": "Het gebouw is in 2015 volledig gerenoveerd met nieuwe isolatie en kozijnen.",
    "conversation_history": []
  }' \
  http://localhost:5000/api/clarify \
  | python3 -m json.tool
```

### Met Python

```python
import requests
import json

data = {
    "filename": "20260710_123456_building.jpg",
    "answer": "Het gebouw is in 2015 volledig gerenoveerd met nieuwe isolatie en kozijnen.",
    "conversation_history": []
}

response = requests.post(
    'http://localhost:5000/api/clarify',
    json=data
)

print(json.dumps(response.json(), indent=2))
```

### Met Postman

1. Selecteer `POST` methode
2. URL: `http://localhost:5000/api/clarify`
3. Ga naar "Body" tab
4. Selecteer "raw" en "JSON"
5. Plak de JSON:
```json
{
  "filename": "20260710_123456_building.jpg",
  "answer": "Het gebouw is in 2015 volledig gerenoveerd",
  "conversation_history": []
}
```
6. Klik "Send"

## 4. Error Cases Testing

### Bestand te groot

```bash
# Maak een test bestand > 10MB
dd if=/dev/zero of=large.jpg bs=1M count=11

# Probeer te uploaden
curl -X POST -F "file=@large.jpg" http://localhost:5000/api/upload
```

**Verwachte response:**
```json
{
  "error": "Bestand te groot (max 10MB)"
}
```

### Ongeldig bestandstype

```bash
# Probeer een .txt bestand te uploaden
curl -X POST -F "file=@test.txt" http://localhost:5000/api/upload
```

**Verwachte response:**
```json
{
  "error": "Bestandstype niet toegestaan"
}
```

### Geen bestand

```bash
curl -X POST http://localhost:5000/api/upload
```

**Verwachte response:**
```json
{
  "error": "Geen bestand gevonden"
}
```

### Bestand niet gevonden (clarify)

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"filename": "nonexistent.jpg", "answer": "test"}' \
  http://localhost:5000/api/clarify
```

**Verwachte response:**
```json
{
  "error": "Bestand niet gevonden"
}
```

## 5. Performance Testing

### Simpele Load Test

```bash
# Test 10 concurrent requests
for i in {1..10}; do
  curl -X POST -F "file=@building.jpg" \
    http://localhost:5000/api/upload &
done
wait
```

### Met Apache Bench

```bash
# Installeer apache bench als je het nog niet hebt
# sudo apt-get install apache2-utils

# Test 100 requests, 10 concurrent
ab -n 100 -c 10 http://localhost:5000/api/health
```

### Met wrk

```bash
# Installeer wrk
# sudo apt-get install wrk

# Test 30 seconden, 10 threads, 100 connections
wrk -t10 -c100 -d30s http://localhost:5000/api/health
```

## 6. Integration Testing

### Complete Flow Test (Python)

```python
import requests
import json

BASE_URL = 'http://localhost:5000'

# 1. Health check
print("1. Testing health endpoint...")
health = requests.get(f'{BASE_URL}/api/health')
print(f"Status: {health.json()['status']}")

# 2. Upload foto
print("\n2. Uploading photo...")
with open('building.jpg', 'rb') as f:
    files = {'file': f}
    upload_response = requests.post(
        f'{BASE_URL}/api/upload',
        files=files
    )

upload_data = upload_response.json()
print(f"Upload success: {upload_data.get('success', False)}")
print(f"Filename: {upload_data.get('filename')}")

# 3. Check voor vragen
if 'analysis' in upload_data and 'verduidelijkingsvragen' in upload_data['analysis']:
    questions = upload_data['analysis']['verduidelijkingsvragen']
    if questions:
        print(f"\n3. Found {len(questions)} clarification questions")
        
        # Beantwoord eerste vraag
        clarify_data = {
            'filename': upload_data['filename'],
            'answer': 'Het gebouw is gebouwd in 1995 en gerenoveerd in 2015',
            'conversation_history': []
        }
        
        clarify_response = requests.post(
            f'{BASE_URL}/api/clarify',
            json=clarify_data
        )
        
        clarify_result = clarify_response.json()
        print(f"Clarification success: {clarify_result.get('success', False)}")

print("\n✅ All tests completed")
```

### Complete Flow Test (Bash)

```bash
#!/bin/bash

echo "=== API Integration Test ==="
echo ""

# 1. Health check
echo "1. Health Check"
curl -s http://localhost:5000/api/health | python3 -m json.tool
echo ""

# 2. Upload
echo "2. Photo Upload"
RESPONSE=$(curl -s -X POST -F "file=@building.jpg" http://localhost:5000/api/upload)
echo $RESPONSE | python3 -m json.tool
echo ""

# Extract filename
FILENAME=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('filename', ''))")
echo "Uploaded filename: $FILENAME"
echo ""

# 3. Clarify
if [ ! -z "$FILENAME" ]; then
    echo "3. Clarification"
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -d "{\"filename\": \"$FILENAME\", \"answer\": \"Gebouwd in 1995\", \"conversation_history\": []}" \
      http://localhost:5000/api/clarify | python3 -m json.tool
fi

echo ""
echo "✅ Tests completed"
```

## 7. Demo Mode Testing

Als je geen API key hebt geconfigureerd, test het systeem in demo mode:

```bash
# Zorg dat OPENAI_API_KEY niet is ingesteld
unset OPENAI_API_KEY

# Start de server
python app.py

# Test upload - zou demo response moeten geven
curl -X POST -F "file=@building.jpg" http://localhost:5000/api/upload
```

**Verwachte demo response:**
```json
{
  "error": "OpenAI API key niet geconfigureerd",
  "demo_response": true,
  "analysis": {
    "constructie": "Demo analyse - Configureer OPENAI_API_KEY",
    "materialen": ["Baksteen", "Beton", "Hout"],
    "isolatie": ["Spouwmuurisolatie mogelijk aanwezig"],
    "vragen": ["Wanneer is het gebouw gebouwd?"]
  }
}
```

## 8. Automated Test Suite

### pytest Example

```python
# test_api.py
import pytest
import requests
from io import BytesIO

BASE_URL = 'http://localhost:5000'

def test_health():
    response = requests.get(f'{BASE_URL}/api/health')
    assert response.status_code == 200
    data = response.json()
    assert data['status'] == 'healthy'

def test_upload_no_file():
    response = requests.post(f'{BASE_URL}/api/upload')
    assert response.status_code == 400
    assert 'error' in response.json()

def test_upload_invalid_type():
    files = {'file': ('test.txt', BytesIO(b'test'), 'text/plain')}
    response = requests.post(f'{BASE_URL}/api/upload', files=files)
    assert response.status_code == 400
    assert 'error' in response.json()

def test_clarify_missing_filename():
    data = {'answer': 'test'}
    response = requests.post(f'{BASE_URL}/api/clarify', json=data)
    assert response.status_code == 400
    assert 'error' in response.json()

# Run tests:
# pytest test_api.py -v
```

## 🎯 Testing Checklist

- [ ] Health endpoint werkt
- [ ] Upload accepteert geldige foto's
- [ ] Upload weigert ongeldige bestanden
- [ ] Analyse geeft gestructureerde response
- [ ] Verduidelijkingsvragen worden gegenereerd
- [ ] Clarify endpoint werkt correct
- [ ] Error handling werkt voor alle edge cases
- [ ] Demo mode werkt zonder API key
- [ ] Performance is acceptabel
- [ ] Concurrent requests worden correct afgehandeld

## 📚 Meer Resources

- **API Documentatie:** Zie README.md
- **Frontend Testing:** Open browser DevTools (F12) en controleer Network tab
- **Logs:** Check Flask console output voor errors

---

**Happy Testing!** 🧪
