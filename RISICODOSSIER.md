# Risicodossier — wat een risicodeskundige moet weten

## Doel

Eén adres → één dossier met alle relevante context voor risico-inspectie en -advies.
Primair via de web-agent `risico-dossier-agent.html` (iPhone-first).
Veldinspectie en foto’s: native **RiskWalk** (`RiskWalk/`) of `gebouw-formulier.html`.

## Wat zit erin

| Onderdeel | Inhoud |
|-----------|--------|
| **BAG** | Pand/VBO, gebruiksdoel, bouwjaar, oppervlakte, status, IDs |
| **Vloeroppervlakte** | BAG m² + optioneel gemeten BVO |
| **Buren** | Nabije/aangrenzende panden (gebruiksdoel, afstand) — géén personen |
| **Water & brandweer** | Kazerne (beroeps/vrijwilligers), opkomst, bluswaterbronnen |
| **Omgeving** | BRO bodem/grondwater, PDOK bestemming, CBS buurtcijfers |
| **Bezetting** | Handmatig: personeel, nacht, BHV, zelfredzaamheid, activiteiten |
| **Inspectiethema’s** | Afgestemd op RiskWalk (elektra, brand, opslag, water, …) |
| **API’s** | Overzicht bronnen + privacygrenzen |

## Wat er bewust níet in zit

- **BRP** (persoonsgegevens) — alleen met wettelijke grondslag; niet in deze app
- Bewonersnamen van buren
- Onbeveiligde API-keys in de browser (live calls via proxy)

## Minimale invoer

1. Postcode  
2. Huisnummer  

Optioneel: toevoeging, plaats, objectnaam.

## Workflow

1. Open `risico-dossier-agent.html` → dossier opbouwen  
2. Controleer BAG / buren / water  
3. Vul bezetting zelf in  
4. Optioneel: meet-agent (BVO), brandweer-agent (detail), open-data-agent  
5. Inspectie: `gebouw-formulier.html` of **RiskWalk** op iPad/iPhone  
6. Exporteer JSON / deel via agent platform  

## Privacyregel

> Buren = gebouwen. Bezetting = wat jij vastlegt. Geen BRP.

Zie ook `API_INTEGRATION.md` (sectie Risicodossier) en `RiskWalk/PRIVACY_SECURITY.md`.
