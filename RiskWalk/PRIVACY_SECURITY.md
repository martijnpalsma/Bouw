# Privacy & Security — RiskWalk

## Dataverwerking

- Inspectiedossiers en foto's worden **lokaal** opgeslagen in Application Support.
- Bestanden gebruiken Data Protection: `completeUntilFirstUserAuthentication`.
- Er is **geen** RiskWalk-backend of analytics-tracking in deze versie.
- `NSPrivacyTracking` = false in `PrivacyInfo.xcprivacy`.

## Toestemmingen

| Capability | Wanneer | Standaard |
|------------|--------|-----------|
| Camera | Inspectiefoto's maken | Gevraagd bij gebruik |
| Microfoon | Dicteren | Gevraagd bij gebruik |
| Spraakherkenning | Transcriptie | Gevraagd bij gebruik; on-device waar mogelijk |
| Fotobibliotheek (schrijven) | Optionele kopie | Uit; alleen bij expliciete toggle |
| Fotobibliotheek (lezen) | Bestaande foto's kiezen | Gevraagd bij PhotosPicker |
| Face ID / toegangscode | App-vergrendeling | Optioneel in Privacy & beveiliging |

## Foto's

- Standaard blijven foto's **alleen** in het inspectiedossier.
- Opslaan in de systeem-Fotobibliotheek is opt-in (`saveAlsoToPhotoLibrary`).
- Thumbnails worden gedownsampled om geheugengebruik te beperken.

## Logging

`AppLogger` logt alleen technische identifiers (afgekorte UUID's, tellingen). Geen bedrijfsnamen, adressen, contactpersonen of antwoordteksten.

## Export / delen

Export naar klembord of Share Sheet bevat inspectiegegevens. De UI waarschuwt om alleen met bevoegde ontvangers te delen.

## AI

Optionele analyse gebruikt Apple Foundation Models **op het apparaat** (indien beschikbaar). Geen externe LLM-API.
