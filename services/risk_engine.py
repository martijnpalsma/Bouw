"""Risico-engine voor taxateur / risicodeskundige (Python)."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from services.opendata_nl import opkomst_risicoklasse

TOPICS = [
    {"id": "activiteiten", "name": "Bedrijfsactiviteiten", "group": "Algemeen"},
    {"id": "gebouwen", "name": "Gebouwen", "group": "Algemeen"},
    {"id": "constructie", "name": "Constructie", "group": "Bouwkundig"},
    {"id": "gevel_dak", "name": "Gevel / dak / kozijnen", "group": "Bouwkundig"},
    {"id": "compartimentering", "name": "Compartimentering", "group": "Brand"},
    {"id": "elektra", "name": "Elektrische installatie", "group": "Installaties"},
    {"id": "verwarming", "name": "Verwarming", "group": "Installaties"},
    {"id": "detectie", "name": "Branddetectie", "group": "Brand"},
    {"id": "blusmiddelen", "name": "Blusmiddelen", "group": "Brand"},
    {"id": "huishouding", "name": "Huishouding / orde & netheid", "group": "Organisatie"},
    {"id": "roken", "name": "Roken / open vuur", "group": "Brand"},
    {"id": "accus", "name": "Accu's en laadplaatsen", "group": "Speciaal risico"},
    {"id": "gevaarlijk", "name": "Gevaarlijke stoffen", "group": "Speciaal risico"},
    {"id": "machines", "name": "Machines / processen", "group": "Speciaal risico"},
    {"id": "opslag", "name": "Opslag", "group": "Speciaal risico"},
    {"id": "buitenopslag", "name": "Buitenopslag", "group": "Speciaal risico"},
    {"id": "inbraak", "name": "Inbraak / diefstal", "group": "Security"},
    {"id": "water", "name": "Water (schade)", "group": "Elementair"},
    {"id": "storm", "name": "Storm", "group": "Elementair"},
    {"id": "bedrijfsschade", "name": "Bedrijfsschade / continuïteit", "group": "Taxatie"},
    {"id": "brandweer", "name": "Brandweer / repressie", "group": "Brand"},
    {"id": "ontruiming", "name": "Ontruiming / BHV", "group": "Organisatie"},
    {"id": "dakveiligheid", "name": "Dakveiligheid / zonnepanelen", "group": "Bouwkundig"},
    {"id": "sandwich", "name": "Sandwichpanelen / isolatiebrand", "group": "Brand"},
]

STANDARD_QUESTIONS = [
    {"id": "activities_main", "text": "Wat zijn de feitelijke bedrijfsactiviteiten op locatie?", "waarom": "Basis voor alle risico-inschatting"},
    {"id": "construction", "text": "Wat is de draagconstructie (beton/staal/hout/metselwerk)?", "waarom": "Brandwerendheid en instortingsgedrag"},
    {"id": "facade", "text": "Gevelbekleding en brandklasse (incl. sandwich/PIR)?", "waarom": "Gevelbrand / snelle uitbreiding"},
    {"id": "compartment", "text": "Hoe is brandcompartimentering (WBDBO) uitgevoerd?", "waarom": "Beperking branduitbreiding"},
    {"id": "electrical", "text": "Ouderdom elektra + laatste NEN 3140 / Scope 8-10 keuring?", "waarom": "Veel voorkomende brandoorzaak"},
    {"id": "heating", "text": "Type verwarming / stookruimte / gasleidingen?", "waarom": "Gas- en stookrisico"},
    {"id": "detection", "text": "Rookmelders / BMC / doormelding naar PAC?", "waarom": "Ontdekkingstijd"},
    {"id": "extinguishers", "text": "Blusmiddelen aanwezig en gekeurd?", "waarom": "Eerste interventie"},
    {"id": "accus", "text": "Lithium-ion accu's of e-bikes laden op locatie?", "waarom": "Thermal runaway risico"},
    {"id": "hazmat", "text": "Gevaarlijke stoffen / ADR / gasflessen?", "waarom": "Escalatie bij brand"},
    {"id": "security", "text": "Inbraakbeveiliging (sloten, alarm, camera)?", "waarom": "Taxatie premie + diefstalschade"},
    {"id": "water_storm", "text": "Wateraccumulatie dak / kelder / stormgevoelige delen?", "waarom": "Elementaire schades"},
    {"id": "bi", "text": "Herbouwwaarde, inventariswaarde, bedrijfsschade-dekking?", "waarom": "Taxatie & verzekeringsadvies"},
    {"id": "solar", "text": "Zonnepanelen op het dak? DC-isolatoren / brandweerprocedure?", "waarom": "Blusveiligheid + dakbrand"},
    {"id": "housekeeping", "text": "Orde & netheid: afval, pallets, rookverbod?", "waarom": "Brandlast en menselijk falen"},
]

FUNCTIE_VRAGEN = {
    "Opslag / warehouse": [
        {"id": "storage_height", "text": "Tot welke hoogte wordt opgeslagen?", "waarom": "Sprinklerontwerp & branduitbreiding"},
        {"id": "storage_sprinkler", "text": "Zijn sprinklers aanwezig en passend bij opslag?", "waarom": "Kritisch voor verzekerbaarheid"},
    ],
    "Horeca": [
        {"id": "food_fryer", "text": "Zijn frituurinstallaties aanwezig?", "waarom": "Keukenbrand"},
        {"id": "food_hood", "text": "Worden afzuigkanalen periodiek gereinigd?", "waarom": "Vetafzetting"},
    ],
    "Hotel": [
        {"id": "hotel_detection", "text": "Automatische detectie + doormelding?", "waarom": "Nachtelijke bezetting"},
    ],
    "Zorginstelling": [
        {"id": "care_self", "text": "Zijn bewoners/cliënten zelfredzaam?", "waarom": "Ontruimingsstrategie"},
    ],
    "Garage / autobedrijf": [
        {"id": "garage_ev", "text": "Worden EV's / lithium-accu's geladen?", "waarom": "Hoog brandrisico"},
    ],
}


def _rank(status: str) -> int:
    return {"ok": 0, "onbekend": 1, "aandacht": 2, "tekort": 3}.get(status, 1)


def _topic(t: dict, status: str, note: str) -> dict:
    return {"id": t["id"], "name": t["name"], "group": t["group"], "status": status, "note": note}


def demo_foto_hints(functie: str) -> dict:
    return {
        "constructie": "Vermoedelijk traditioneel metselwerk of beton (niet geverifieerd)",
        "gevel": "Gevelmateriaal uit foto niet hard vastgesteld — controleer brandklasse",
        "materialen_gevel": ["Nader te inspecteren"],
        "materialen_dak": ["Nader te inspecteren"],
        "kozijnen": ["Nader te inspecteren"],
        "isolatie": [],
        "sandwich": "Let op sandwichpanelen bij hallen" if functie and any(x in functie.lower() for x in ("industrie", "opslag")) else None,
    }


def build_report(
    locatie: Optional[dict],
    pand: Optional[dict],
    brandweer: list,
    water: Optional[dict],
    functie: str,
    foto_hints: Optional[dict] = None,
    antwoorden: Optional[dict] = None,
    extra: Optional[dict] = None,
) -> dict:
    foto_hints = foto_hints or {}
    antwoorden = antwoorden or {}
    extra = extra or {}
    cbs = extra.get("cbs") if isinstance(extra.get("cbs"), dict) else None
    weer = extra.get("weer") if isinstance(extra.get("weer"), dict) else None
    wegen = extra.get("wegen") if isinstance(extra.get("wegen"), dict) else None
    perceel = extra.get("perceel") if isinstance(extra.get("perceel"), dict) else None

    bouwjaar = (pand or {}).get("bouwjaar") or foto_hints.get("bouwjaar")
    age = (datetime.now().year - bouwjaar) if bouwjaar else None
    nearest = brandweer[0] if brandweer else None
    risk_class = (
        opkomst_risicoklasse(nearest["distance_km"], nearest["duration_min"]) if nearest else "Onbekend"
    )

    topics = [
        _evaluate(
            t, locatie, pand, brandweer, water, functie, foto_hints, antwoorden,
            bouwjaar, age, nearest, risk_class, cbs, weer, wegen
        )
        for t in TOPICS
    ]
    raw = sum(_rank(t["status"]) for t in topics)
    score = round(100 - (raw / (len(topics) * 3)) * 100)
    niveau = "laag" if score >= 75 else "gemiddeld" if score >= 55 else "hoog"
    tekortkomingen = [t for t in topics if t["status"] in ("tekort", "aandacht")]
    openstaand = [t for t in topics if t["status"] == "onbekend"]

    woz_k = cbs.get("gemiddelde_woningwaarde_k") if cbs else None
    taxatie = {
        "herbouwwaarde_indicatie": (
            f"CBS gem. woningwaarde buurt ± €{woz_k * 1000:,.0f} (indicatief — geen herbouwwaarde)".replace(",", ".")
            if isinstance(woz_k, (int, float))
            else "n.n.b. — vraag taxateur/calculatie"
        ),
        "inventaris": "n.n.b.",
        "bedrijfsschade": "afhankelijk van omzet / max. uitkeringstermijn",
        "premie_drivers": [t["name"] for t in tekortkomingen[:6]],
        "blootstelling": {
            "bevolkingsdichtheid": cbs.get("bevolkingsdichtheid") if cbs else None,
            "bedrijfsvestigingen": cbs.get("bedrijfsvestigingen") if cbs else None,
            "omgevingsadressendichtheid": cbs.get("omgevingsadressendichtheid") if cbs else None,
        },
        "perceel_m2": perceel.get("grootte_m2") if perceel else None,
    }

    return {
        "timestamp": datetime.now().isoformat(),
        "locatie": locatie,
        "pand": pand,
        "brandweer": {"nearest": nearest, "stations": brandweer, "riskClass": risk_class, "water": water},
        "extra": {"cbs": cbs, "weer": weer, "wegen": wegen, "perceel": perceel},
        "functie": functie,
        "bouwjaar": bouwjaar,
        "age": age,
        "score": score,
        "niveau": niveau,
        "topics": topics,
        "tekortkomingen": tekortkomingen,
        "openstaand": openstaand,
        "vragen": _questions(functie, topics),
        "materialen": _materials(pand, foto_hints, bouwjaar),
        "taxatie": taxatie,
        "conclusie": _conclusion(niveau, score, nearest, risk_class, pand, functie, openstaand, tekortkomingen, cbs, weer),
    }


def _evaluate(t, locatie, pand, brandweer, water, functie, foto_hints, a, bouwjaar, age, nearest, risk_class, cbs=None, weer=None, wegen=None):
    tid = t["id"]
    fn = (functie or "").lower()
    cbs = cbs or {}
    weer = weer or {}
    wegen = wegen or {}

    if tid == "activiteiten":
        if a.get("activities_main"):
            return _topic(t, "ok", a["activities_main"])
        if functie:
            return _topic(t, "aandacht", f"Opgegeven functie: {functie}. Verifieer feitelijke activiteiten.")
        return _topic(t, "onbekend", "Nog geen activiteiten vastgelegd.")

    if tid == "gebouwen":
        if pand:
            return _topic(
                t,
                "ok",
                f"BAG-pand: bouwjaar {pand.get('bouwjaar')}, status {pand.get('status')}, VBO’s {pand.get('aantal_verblijfsobjecten')}",
            )
        return _topic(t, "onbekend", "Geen pandgegevens uit BAG.")

    if tid == "constructie":
        if a.get("construction"):
            return _topic(t, "ok", a["construction"])
        if foto_hints.get("constructie"):
            return _topic(t, "aandacht", foto_hints["constructie"])
        return _topic(t, "onbekend", "Draagconstructie niet vastgesteld.")

    if tid == "gevel_dak":
        if a.get("facade"):
            return _topic(t, "ok", a["facade"])
        return _topic(t, "aandacht", foto_hints.get("gevel") or "Controleer brandklasse gevel/dakisolatie.")

    if tid == "compartimentering":
        if a.get("compartment"):
            low = "geen" in a["compartment"].lower()
            return _topic(t, "tekort" if low else "ok", a["compartment"])
        return _topic(t, "onbekend", "WBDBO / branddeuren / doorvoeringen — kritiek inspectiepunt.")

    if tid == "elektra":
        if a.get("electrical"):
            return _topic(t, "ok", a["electrical"])
        if age and age > 30:
            return _topic(t, "aandacht", f"Bouwjaar ±{bouwjaar}: vraag recente elektra-keuring.")
        return _topic(t, "onbekend", "Geen keuringsinformatie bekend.")

    if tid == "verwarming":
        if a.get("heating"):
            return _topic(t, "ok", a["heating"])
        gas = cbs.get("perc_aardgaswoningen")
        if isinstance(gas, (int, float)) and gas >= 70:
            return _topic(t, "aandacht", f"CBS: {gas}% aardgaswoningen in buurt (gem. verbruik {cbs.get('gem_aardgasverbruik') or '?'} m³). Verifieer CV/gasleidingen op object.")
        return _topic(t, "onbekend", "Type CV/stookruimte onbekend.")

    if tid == "detectie":
        if a.get("detection"):
            low = any(x in a["detection"].lower() for x in ("geen", "nee"))
            return _topic(t, "tekort" if low else "ok", a["detection"])
        if any(x in fn for x in ("hotel", "zorg", "opslag")):
            return _topic(t, "aandacht", "Functie vraagt om adequate detectie — status onbekend.")
        return _topic(t, "onbekend", "Detectie/doormelding niet vastgesteld.")

    if tid == "blusmiddelen":
        if a.get("extinguishers"):
            low = any(x in a["extinguishers"].lower() for x in ("geen", "nee"))
            return _topic(t, "tekort" if low else "ok", a["extinguishers"])
        return _topic(t, "onbekend", "Handblussers/haspels/sprinkler niet bevestigd.")

    if tid == "huishouding":
        return _topic(t, "onbekend", a.get("housekeeping") or "Orde & netheid tijdens inspectie beoordelen.")

    if tid == "roken":
        return _topic(t, "onbekend", "Rookbeleid / open vuur / hot work permit controleren.")

    if tid == "accus":
        if a.get("accus"):
            hot = any(x in a["accus"].lower() for x in ("ja", "lithium", "laden"))
            return _topic(t, "aandacht" if hot else "ok", a["accus"])
        if any(x in fn for x in ("garage", "opslag", "industrie")):
            return _topic(t, "aandacht", "Functie: vraag expliciet naar lithium-laden / EV.")
        return _topic(t, "onbekend", "Lithium-ion laden: vrije ruimte ≥2 m, detectie, niet onbeheerd.")

    if tid == "gevaarlijk":
        if a.get("hazmat"):
            hot = any(x in a["hazmat"].lower() for x in ("ja", "aanwezig"))
            return _topic(t, "aandacht" if hot else "ok", a["hazmat"])
        if any(x in fn for x in ("industrie", "metaal", "garage", "opslag")):
            return _topic(t, "aandacht", "Functie suggereert mogelijke gevaarlijke stoffen.")
        return _topic(t, "onbekend", "ADR/stoffenlijst opvragen.")

    if tid == "machines":
        if any(x in fn for x in ("industrie", "metaal", "hout", "garage")):
            return _topic(t, "aandacht", "Procesgebonden brandrisico’s inventariseren.")
        return _topic(t, "ok", "Geen zware processen verwacht — verifieer.")

    if tid == "opslag":
        if any(x in fn for x in ("opslag", "winkel", "industrie")):
            return _topic(t, "aandacht", "Opslaghoogte, brandlast en sprinklercompatibiliteit checken.")
        return _topic(t, "onbekend", "Interne opslag beoordelen.")

    if tid == "buitenopslag":
        return _topic(t, "onbekend", "Afstand tot gevel, containers, pallets, gasflessen buiten.")

    if tid == "inbraak":
        if a.get("security"):
            return _topic(t, "ok", a["security"])
        return _topic(t, "aandacht", "Taxatie: slotenklasse, alarm, camera — premie-relevant.")

    if tid == "water":
        if a.get("water_storm"):
            return _topic(t, "aandacht" if any(x in a["water_storm"].lower() for x in ("lekkage", "overlast", "accumulatie")) else "ok", a["water_storm"])
        notes = []
        if weer.get("elevation_m") is not None:
            notes.append(f"hoogte ±{weer['elevation_m']} m (proxy overstroming: {weer.get('overstroming_hoogte_proxy')})")
        if weer.get("max_neerslag_7d_mm") is not None:
            notes.append(f"max neerslag 7d {weer['max_neerslag_7d_mm']} mm ({weer.get('water_neerslag_indicatie')})")
        if notes:
            status = "aandacht" if weer.get("overstroming_hoogte_proxy") == "hoog" or weer.get("water_neerslag_indicatie") == "hoog" else "aandacht" if weer.get("overstroming_hoogte_proxy") == "middel" else "ok"
            if weer.get("overstroming_hoogte_proxy") == "laag" and weer.get("water_neerslag_indicatie") == "laag":
                status = "ok"
            return _topic(t, status, "Open-Meteo: " + "; ".join(notes) + ". Geen officiële LIWO-status — controleer kelder/dakafvoer.")
        return _topic(t, "onbekend", "Dakafvoer, kelder, leidingbreukscenario’s.")

    if tid == "storm":
        if weer.get("max_windstoten_7d_kmh") is not None:
            st = weer.get("storm_indicatie") or "laag"
            status = "tekort" if st == "hoog" else "aandacht" if st == "middel" else "ok"
            return _topic(t, status, f"Open-Meteo: max windstoten 7d {weer['max_windstoten_7d_kmh']} km/h ({st}). Check dak/gevel/luifels.")
        return _topic(t, "onbekend", "Dakverankering, gevelplaten, luifels, bomen nabij.")

    if tid == "bedrijfsschade":
        if a.get("bi"):
            return _topic(t, "ok", a["bi"])
        return _topic(t, "aandacht", "Vraag omzetafhankelijkheid, uitwijk, max. schadeperiode.")

    if tid == "brandweer":
        parts = []
        if nearest:
            parts.append(f"Opkomst ±{nearest['duration_min']} min / {nearest['distance_km']} km ({nearest['name']}).")
        if cbs.get("afstand_brandweer_km") is not None:
            parts.append(f"CBS gem. afstand brandweer {cbs['afstand_brandweer_km']} km.")
        if wegen.get("bereikbaarheid_indicatie"):
            parts.append(f"NWB: {wegen['bereikbaarheid_indicatie']}")
        if not parts:
            return _topic(t, "onbekend", "Geen kazerne/CBS — veiligheidsregio handmatig checken.")
        note = " ".join(parts)
        if risk_class == "Hoog" or "Beperkt" in (wegen.get("bereikbaarheid_indicatie") or ""):
            return _topic(t, "tekort" if risk_class == "Hoog" else "aandacht", note)
        if risk_class == "Gemiddeld":
            return _topic(t, "aandacht", note)
        return _topic(t, "ok", note)

    if tid == "ontruiming":
        if any(x in fn for x in ("hotel", "zorg", "onderwijs")):
            return _topic(t, "aandacht", "Kwetsbare populatie: ontruimingsplan + oefeningen.")
        return _topic(t, "onbekend", "BHV-organisatie en ontruimingsplattegronden controleren.")

    if tid == "dakveiligheid":
        if a.get("solar"):
            hot = any(x in a["solar"].lower() for x in ("ja", "paneel"))
            return _topic(t, "aandacht" if hot else "ok", a["solar"])
        return _topic(t, "onbekend", "PV-installatie, ballast, doorvoeren, blusprocedure.")

    if tid == "sandwich":
        if foto_hints.get("sandwich"):
            return _topic(t, "aandacht", foto_hints["sandwich"])
        if any(x in fn for x in ("industrie", "opslag")):
            return _topic(t, "aandacht", "Vraag kernisolatie sandwichpanelen (PIR/PUR/MW).")
        return _topic(t, "onbekend", "Isolatiebrandgedrag niet vastgesteld.")

    return _topic(t, "onbekend", "")


def _questions(functie: str, topics: list) -> list:
    qs = list(STANDARD_QUESTIONS)
    qs.extend(FUNCTIE_VRAGEN.get(functie, []))
    unknown = {t["id"] for t in topics if t["status"] in ("onbekend", "aandacht")}
    out = []
    for q in qs:
        prio = "hoog" if q["id"] in unknown or any(x in (q["id"] + q["text"]).lower() for x in ("accus", "compartment", "detection", "electrical", "lithium", "sprinkler")) else "normaal"
        out.append({"vraag": q["text"], "reden": q["waarom"], "id": q["id"], "prioriteit": prio})
    out.sort(key=lambda x: 0 if x["prioriteit"] == "hoog" else 1)
    return out[:12]


def _materials(pand, foto_hints, bouwjaar):
    isolatie = []
    if bouwjaar:
        if bouwjaar >= 1992:
            isolatie.append("Spouw-/dakisolatie waarschijnlijk (bouwbesluit-tijdperk)")
        elif bouwjaar >= 1975:
            isolatie.append("Mogelijk nageïsoleerd — verifiëren")
        else:
            isolatie.append("Oudere bouw: isolatie vaak beperkt of later aangebracht")
    isolatie.extend(foto_hints.get("isolatie") or [])
    return {
        "gevel": foto_hints.get("materialen_gevel") or ["Nader te bepalen"],
        "dak": foto_hints.get("materialen_dak") or ["Nader te bepalen"],
        "kozijnen": foto_hints.get("kozijnen") or ["Nader te bepalen"],
        "isolatie": isolatie,
        "gebruiksdoel_bag": (pand or {}).get("gebruiksdoel") or [],
    }


def _conclusion(niveau, score, nearest, risk_class, pand, functie, openstaand, tekortkomingen, cbs=None, weer=None):
    parts = [f'Risiconiveau {niveau.upper()} (score {score}/100) voor functie “{functie or "onbekend"}”.']
    if pand and pand.get("bouwjaar"):
        parts.append(f'BAG-bouwjaar {pand["bouwjaar"]}, status “{pand.get("status") or "?"}”.')
    if nearest:
        parts.append(
            f'Dichtstbijzijnde kazerne: {nearest["name"]} (±{nearest["duration_min"]} min, opkomstklasse {risk_class}).'
        )
    if cbs and cbs.get("bevolkingsdichtheid"):
        parts.append(f'CBS blootstelling: {cbs["bevolkingsdichtheid"]} inw/km², {cbs.get("bedrijfsvestigingen") or "?"} bedrijven.')
    if weer and weer.get("elevation_m") is not None:
        parts.append(f'Hoogte ±{weer["elevation_m"]} m (overstromingsproxy {weer.get("overstroming_hoogte_proxy")}).')
    parts.append(
        f"{len(tekortkomingen)} aandacht-/tekortpunten, {len(openstaand)} onderwerpen nog onbekend — deze bepalen de inspectieagenda."
    )
    return " ".join(parts)
