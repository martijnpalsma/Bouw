# 📱 Foto Analyse App - iOS

Native SwiftUI iOS app voor AI-powered gebouw foto analyse.

## ✨ Features

- 📸 **Foto Upload**: Camera of foto bibliotheek
- 🤖 **AI Analyse**: GPT-4 Vision via Flask API
- 🏗️ **Constructie Analyse**: Type, draagconstructie, verdiepingen
- 🧱 **Materiaal Detectie**: Gevel, dak, kozijnen identificatie
- 🌡️ **Isolatie Inschatting**: Geschatte isolatie met waarschijnlijkheid
- 📋 **Staat Beoordeling**: Algemene conditie en aandachtspunten
- 📅 **Bouwperiode**: Geschatte periode op basis van architectuur
- ❓ **Interactieve Vragen**: Verduidelijkingsvragen voor betere analyse
- ⚙️ **Configureerbaar**: API URL aanpasbaar in Settings

## 📋 Vereisten

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Flask backend draaiend op localhost of netwerk

## 🚀 Installatie

### 1. Flask Backend Starten

Zorg dat de Flask API draait:

```bash
cd /workspace
python app.py
```

Server draait op `http://localhost:5000`

### 2. Open Xcode Project

```bash
open FotoAnalyseApp/FotoAnalyseApp.xcodeproj
```

### 3. Configureer API URL

- Open de app in simulator of op device
- Ga naar Settings (⚙️ icoon)
- Voer API URL in: `http://localhost:5000` (simulator) of `http://YOUR_IP:5000` (device)
- Klik "Test" om verbinding te checken
- Klik "Opslaan"

### 4. Run de App

- Selecteer target device/simulator
- Klik Run (⌘+R)

## 📁 Project Structuur

```
FotoAnalyseApp/
├── FotoAnalyseApp.xcodeproj          # Xcode project
└── FotoAnalyseApp/
    ├── FotoAnalyseAppApp.swift       # App entry point
    │
    ├── Views/                         # UI Views
    │   ├── ContentView.swift         # Hoofd view met upload
    │   ├── ResultsView.swift         # Analyse resultaten display
    │   ├── CameraView.swift          # Camera interface wrapper
    │   └── SettingsView.swift        # API configuratie
    │
    ├── Models/                        # Data Models
    │   └── AnalysisModels.swift      # Codable structs voor API
    │
    ├── Services/                      # Business Logic
    │   └── AnalysisService.swift     # API communicatie service
    │
    └── Resources/
        └── Info.plist                 # App configuratie & permissions
```

## 🔧 Configuratie

### Info.plist Permissions

De app vraagt om camera en foto bibliotheek toegang:

```xml
<key>NSCameraUsageDescription</key>
<string>We hebben toegang tot de camera nodig om foto's van gebouwen te maken voor analyse</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We hebben toegang tot je fotobibliotheek nodig om gebouwfoto's te selecteren voor analyse</string>
```

### API Endpoints

De app gebruikt de volgende endpoints:

- `GET /api/health` - Health check
- `POST /api/upload` - Upload & analyseer foto
- `POST /api/clarify` - Beantwoord verduidelijkingsvragen

## 💻 Code Voorbeelden

### API Service

```swift
@MainActor
class AnalysisService: ObservableObject {
    @Published var uploadState: UploadState = .idle
    @Published var currentAnalysis: AnalysisResponse?
    
    func uploadAndAnalyze(image: UIImage) async {
        uploadState = .uploading
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadState = .error("Kan foto niet verwerken")
            return
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", 
                        forHTTPHeaderField: "Content-Type")
        
        // Build request body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"gebouw.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        uploadState = .analyzing
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            currentAnalysis = response
            uploadState = .completed(response)
        } catch {
            uploadState = .error(error.localizedDescription)
        }
    }
}
```

### SwiftUI View

```swift
struct ContentView: View {
    @EnvironmentObject var analysisService: AnalysisService
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Upload section
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Foto Bibliotheek", systemImage: "photo")
                        }
                        
                        // Results
                        if case .completed(let response) = analysisService.uploadState {
                            ResultsView(response: response)
                        }
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        await analysisService.uploadAndAnalyze(image: image)
                    }
                }
            }
        }
    }
}
```

## 🔒 Privacy & Security

- ✅ Camera access alleen op verzoek
- ✅ Foto's blijven lokaal
- ✅ Upload alleen via expliciete actie
- ✅ API configuratie lokaal opgeslagen
- ✅ Geen tracking of analytics
- ✅ Geen data persistentie (tenzij gewenst)

## 🐛 Troubleshooting

### App kan API niet bereiken

**Simulator:**
- Gebruik `http://localhost:5000`
- Controleer of Flask draait

**Fysiek Device:**
- Gebruik `http://YOUR_IP_ADDRESS:5000`
- Zorg dat Mac en iPhone op zelfde netwerk zitten
- Check firewall instellingen

**Test verbinding:**
```bash
# Op Mac
ipconfig getifaddr en0

# Test from terminal
curl http://localhost:5000/api/health
```

### Camera werkt niet

- Check Info.plist permissions
- Herstart app na eerste permission denial
- Test in simulator met drag & drop foto

### Upload faalt

- Check bestandsgrootte (max 10MB)
- Controleer bestandsformaat (JPG, PNG)
- Bekijk Flask logs voor errors

### JSON Parsing Error

- Update backend API
- Check response format matches AnalysisModels
- Enable debug prints in AnalysisService

## 📱 Screenshots

Zie `ios-foto-analyse-preview.html` voor interactieve preview van de app.

## 🔗 Integratie

De app werkt naadloos met:
- Flask backend (`app.py`)
- GPT-4 Vision API
- Agent Platform Dashboard
- Bestaande gebouw analyse workflow

## 🚀 Deployment

### TestFlight

1. Archive in Xcode
2. Upload naar App Store Connect
3. Create TestFlight build
4. Invite testers

### App Store

1. Complete app metadata
2. Add screenshots
3. Submit for review
4. Configure pricing & availability

## 📄 Licentie

© 2026 Bouw Informatie Systeem - Alle rechten voorbehouden

## 🤝 Contributing

1. Fork het project
2. Create feature branch
3. Test grondig op device
4. Submit pull request

## 📞 Support

Voor vragen of problemen:
- Check `FOTO_ANALYSE_README.md` voor backend docs
- Bekijk `API_TESTING.md` voor API testing
- Test met `ios-foto-analyse-preview.html`

---

**Built with SwiftUI & ❤️**
