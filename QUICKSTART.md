# 🚀 Quick Start Gids

Deze snelstart gids helpt je binnen 5 minuten aan de slag met het Gebouw Foto Analyse systeem.

## Stap 1: Installeer Dependencies (1 minuut)

### Automatisch (Aanbevolen)

**Linux/Mac:**
```bash
./start.sh
```

**Windows:**
```bash
start.bat
```

De scripts installeren automatisch alle benodigde dependencies.

### Handmatig

```bash
pip install -r requirements.txt
```

## Stap 2: Configureer API Key (1 minuut)

### Voor Echte AI Analyse (Optioneel)

1. Kopieer het voorbeeld configuratiebestand:
```bash
cp .env.example .env
```

2. Bewerk `.env` en voeg je OpenAI API key toe:
```env
OPENAI_API_KEY=sk-your-actual-api-key-here
```

**OpenAI API Key verkrijgen:**
1. Ga naar [platform.openai.com](https://platform.openai.com)
2. Maak een account of log in
3. Ga naar API Keys
4. Klik "Create new secret key"
5. Kopieer de key naar `.env`

### Demo Mode (Geen API Key Nodig)

Als je geen API key configureert, werkt het systeem in demo mode met voorbeeldanalyses.

## Stap 3: Start de Applicatie (30 seconden)

### Optie A: Gebruik Startup Script

**Linux/Mac:**
```bash
./start.sh
```

**Windows:**
```bash
start.bat
```

### Optie B: Direct Python

```bash
python app.py
```

De server start op `http://localhost:5000`

## Stap 4: Open de Interface (30 seconden)

Open in je browser:
```
http://localhost:5000/foto-analyse.html
```

Of start vanaf de hoofdpagina:
```
http://localhost:5000
```

## Stap 5: Analyseer Je Eerste Foto (2 minuten)

1. **Upload een foto:**
   - Sleep een gebouwfoto naar de upload zone
   - Of klik op de upload zone om een bestand te selecteren

2. **Start de analyse:**
   - Klik op "🔍 Analyseer Gebouw"
   - Wacht terwijl de AI de foto analyseert

3. **Bekijk resultaten:**
   - Zie constructie details
   - Bekijk materiaallijsten
   - Lees isolatie inschattingen
   - Check de staat van het gebouw

4. **Beantwoord vragen (optioneel):**
   - Als de AI vragen heeft, beantwoord deze
   - Klik "📨 Verstuur Antwoord"
   - Ontvang een verfijnde analyse

## ✅ Checklist

- [ ] Dependencies geïnstalleerd
- [ ] `.env` bestand aangemaakt (optioneel)
- [ ] Server draait op port 5000
- [ ] Interface toegankelijk in browser
- [ ] Eerste foto geüpload en geanalyseerd

## 🎯 Volgende Stappen

- Lees de volledige [README.md](README.md) voor meer details
- Probeer verschillende types gebouwfoto's
- Experimenteer met verduidelijkingsvragen
- Integreer met bestaande systemen

## 🆘 Problemen?

### Server start niet
```bash
# Controleer of port 5000 vrij is
lsof -i :5000  # Linux/Mac
netstat -ano | findstr :5000  # Windows

# Of gebruik een andere port
PORT=8000 python app.py
```

### Dependencies installeren mislukt
```bash
# Update pip
pip install --upgrade pip

# Probeer opnieuw
pip install -r requirements.txt
```

### API Key werkt niet
- Controleer of `.env` bestand bestaat in de project root
- Verifieer dat de key begint met `sk-`
- Herstart de server na het toevoegen van de key

### Upload werkt niet
- Controleer bestandsformaat (JPG, PNG, GIF, WebP)
- Verifieer bestandsgrootte (max 10MB)
- Check browser console voor errors (F12)

## 💡 Tips

1. **Beste Foto's:**
   - Goed verlicht
   - Duidelijk zicht op gevel
   - Volledige gebouwen
   - Meerdere hoeken voor betere analyse

2. **Demo Mode:**
   - Werkt zonder API key
   - Toont voorbeeld analyses
   - Ideaal voor testing

3. **Performance:**
   - Eerste analyse kan 10-30 seconden duren
   - Afhankelijk van foto complexiteit
   - Netwerk snelheid beïnvloedt responstijd

## 📖 Meer Informatie

- **Volledige Documentatie:** [README.md](README.md)
- **API Referentie:** Zie README.md API Endpoints sectie
- **Configuratie:** Zie README.md Configuratie sectie

---

**Veel succes met je analyses!** 🏗️
