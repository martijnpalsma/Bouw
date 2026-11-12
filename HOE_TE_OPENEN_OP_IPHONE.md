# 📱 Bouw Informatie Systeem op iPhone Bekijken

## 🚀 Snelste Methode: Lokale Server

### Optie 1: Python Server (Eenvoudigste)

**Stap 1: Start de server**
```bash
# In de /workspace directory
python3 -m http.server 8000
```

**Stap 2: Vind je computer's IP adres**

**Op Mac:**
```bash
ipconfig getifaddr en0
# Of
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Op Windows:**
```bash
ipconfig
# Zoek naar "IPv4 Address" onder je WiFi adapter
```

**Op Linux:**
```bash
hostname -I
```

**Stap 3: Open op iPhone**
```
http://JE-IP-ADRES:8000
Bijvoorbeeld: http://192.168.1.10:8000
```

---

## 🌐 Optie 2: Node.js Server met QR Code

Ik maak een script voor je:

### Installeer (eenmalig)
```bash
npm install -g http-server qrcode-terminal
```

### Start met QR Code
```bash
http-server -p 8000 -o
```

Dit opent automatisch je browser en toont een QR code die je kunt scannen met je iPhone!

---

## 🔗 Optie 3: Ngrok (Publiek Toegankelijk)

Voor als je het wilt delen of vanaf elk netwerk wilt openen:

### Installeer Ngrok
1. Download van https://ngrok.com/download
2. Of via brew: `brew install ngrok`

### Start je lokale server
```bash
python3 -m http.server 8000
```

### Start Ngrok in nieuwe terminal
```bash
ngrok http 8000
```

### Gebruik de URL
Ngrok geeft je een URL zoals: `https://abc123.ngrok.io`
Open deze op je iPhone - werkt overal met internet!

---

## 📲 Optie 4: GitHub Pages (Permanent Online)

### Stap 1: Push naar GitHub (al gedaan)
De code staat al in je repository!

### Stap 2: Activeer GitHub Pages
1. Ga naar je repository op GitHub
2. Settings → Pages
3. Source: Kies je branch (main of cursor/brandweer-watervoorziening-agent-6057)
4. Save

### Stap 3: Open op iPhone
Na een paar minuten is het beschikbaar op:
```
https://jouw-username.github.io/Bouw/
```

---

## 🏠 Optie 5: Live Server Extension (VS Code)

Als je VS Code gebruikt:

1. Installeer "Live Server" extension
2. Right-click op `index.html`
3. Klik "Open with Live Server"
4. Gebruik je computer's IP + poort op iPhone

---

## ⚡ Quick Start Script

Ik maak een script voor je dat alles automatisch doet:

```bash
# start-server.sh
#!/bin/bash

# Krijg IP adres
IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')

echo "🚀 Starting Bouw Informatie Systeem Server..."
echo ""
echo "📱 Open op je iPhone:"
echo "   http://$IP:8000"
echo ""
echo "📋 Of scan deze QR code:"
echo ""

# Start Python server
python3 -m http.server 8000
```

---

## 🔧 Troubleshooting

### Kan niet verbinden?

**Check 1: Zelfde WiFi Netwerk**
- Computer en iPhone moeten op hetzelfde WiFi netwerk zitten
- Check je WiFi settings op beide apparaten

**Check 2: Firewall**
- Mac: System Preferences → Security & Privacy → Firewall
- Windows: Windows Defender Firewall → Allow an app
- Sta Python of je server toe

**Check 3: Poort al in gebruik?**
```bash
# Gebruik een andere poort
python3 -m http.server 8080
# Of
python3 -m http.server 3000
```

**Check 4: HTTPS vereist?**
Sommige features vereisen HTTPS. Gebruik dan ngrok of GitHub Pages.

---

## 📱 Direct Testen

### Methode 1: Simpelste Start
```bash
cd /workspace
python3 -m http.server 8000
```

Dan op je iPhone:
1. Open Safari
2. Ga naar: `http://[JE-COMPUTER-IP]:8000`
3. Klaar! 🎉

### Methode 2: Met Auto IP Detection
```bash
cd /workspace
IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')
echo "Open op iPhone: http://$IP:8000"
python3 -m http.server 8000
```

---

## 🎯 Aanbevolen Workflow

**Voor Development/Testing:**
→ Optie 1 (Python Server) - Snelst en simpelst

**Voor Demonstraties:**
→ Optie 3 (Ngrok) - Werkt altijd, overal

**Voor Productie:**
→ Optie 4 (GitHub Pages) - Gratis en altijd online

---

## 🆘 Hulp Nodig?

Als het niet werkt, check:
1. ✅ Zijn computer en iPhone op hetzelfde WiFi?
2. ✅ Draait de server? (zie terminal output)
3. ✅ Is de firewall uit of toegestaan?
4. ✅ Klopt het IP adres?
5. ✅ Gebruikte de juiste poort? (8000)

---

## 📞 Quick Commands Overzicht

```bash
# Start server
python3 -m http.server 8000

# Vind je IP
ipconfig getifaddr en0                    # Mac
ipconfig                                   # Windows
hostname -I                                # Linux

# Test lokaal eerst
open http://localhost:8000                 # Mac
start http://localhost:8000                # Windows

# Stop server
Ctrl + C
```

---

## 🎉 Success!

Als het werkt zie je op je iPhone:
- ✅ De homepage met Getting Started
- ✅ Alle 6 agents
- ✅ Workflow diagram
- ✅ Volledig responsive design
- ✅ Touch-friendly interface

Veel succes! 📱✨
