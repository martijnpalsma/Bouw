# RiskWalk — iOS inspectie-app

Native SwiftUI-app voor risicodeskundigen (iPad-first), gebaseerd op de Bitrig-prototypecode.

## Privacy & security (deze PR)

| Maatregel | Implementatie |
|-----------|----------------|
| Usage descriptions | `Resources/Info.plist` (camera, microfoon, spraak, foto's, Face ID) |
| Privacy Manifest | `Resources/PrivacyInfo.xcprivacy` (geen tracking) |
| Lokale opslag | `SecureStore` in Application Support met `completeUntilFirstUserAuthentication` |
| Foto's | `PhotoStore` als JPEG op schijf (niet alleen in geheugen); fotobibliotheek **opt-in** |
| Toestemmingen | `PermissionManager` vraagt toegang vóór camera/dicteren/fotokeuze |
| App-vergrendeling | Optionele Face ID / toegangscode via `AppLockService` |
| Logging | `AppLogger` logt géén klantnamen/adressen |
| AI | Alleen on-device Foundation Models indien beschikbaar; geen RiskWalk-cloud |

## Openen in Xcode

1. Open `RiskWalk/RiskWalk.xcodeproj` op een Mac met Xcode 16+.
2. Selecteer een iPad/iPhone simulator of device.
3. Build & Run (`⌘R`).
4. Tests: `⌘U`.

## Architectuur (kort)

```
RiskWalk/
  App/           # Entry + dashboard/workspace routing + lock screen
  Models/        # Building (UUID + Gxx), questions, snapshot, AppFrame/AppRouter
  Services/      # SecureStore (multi-dossier), PhotoStore, Permissions, Logger, AppLock
  Views/         # Dashboard, workspace frames, export, security
  Resources/     # Info.plist, PrivacyInfo.xcprivacy
RiskWalkTests/   # Gebouwnnummering, conditional questions, persistence
```

## Dashboard & frames

- **Dashboard**: overzicht van dossiers (naam, plaats, datum, status, voortgang)
- Acties: nieuwe inspectie, openen, dupliceren, archiveren, exporteren, verwijderen
- Snelle frame-knoppen per dossier: Openen / Inspectie / Foto's / Rapport
- **Workspace**: iPad-sidebar of iPhone-segmented control om direct te wisselen tussen
  Dossier → Inspectie → Vragenlijst → Foto's → Samenvatting zonder dataverlies

## Bekende vervolgstappen

- Volledige inventaris/goederen-records (I01/HB01)
- PDF-export met embedded foto's
- Meerdere dossiers / dashboard
- SwiftData-migratie wanneer multi-dossier nodig is
