# FotoAnalyseApp (iPhone / Xcode)

Native SwiftUI-app voor foto-analyse via Flask (`app.py` + GPT-4 Vision).

## Snel op je iPhone

### Optie A — RisicoScan in Safari (geen Xcode)
Op je Mac/PC:

```bash
cd lokaal-demo && ./START-LOKAAL.sh
```

Open op iPhone (zelfde wifi) het getoonde telefoon-adres, bv. `http://192.168.x.x:8765`.

### Optie B — Deze native app
1. Open `FotoAnalyseApp.xcodeproj` in Xcode op een Mac.
2. Start Flask: `python3 app.py` (poort 5000), bereikbaar op je LAN-IP.
3. iPhone via USB of zelfde wifi → selecteer device → Run (⌘R).
4. In de app: Settings → API URL `http://JOUW-IP:5000` → Test → Opslaan.

Vereist: iOS 17+, Xcode 15+, Apple Developer account voor fysiek device.

## Endpoints
- `GET /api/health`
- `POST /api/upload`
- `POST /api/clarify`
