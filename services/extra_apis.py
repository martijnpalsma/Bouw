"""
Extra openbare APIs voor risicodeskundige / risk engineer.
- CBS Wijken en Buurten (PDOK WFS 2024)
- Kadaster Kadastrale Kaart (perceelgrootte)
- RWS NWB wegen (bereikbaarheid)
- Open-Meteo (hoogte + wind/neerslag)
"""

from __future__ import annotations

import json
import math
from typing import Any, Optional
from urllib.parse import urlencode
from urllib.request import Request, urlopen

UA = "RisicoScanLocal/1.1 (risicodeskundige / risk engineer)"
CBS_WFS = "https://service.pdok.nl/cbs/wijkenbuurten/2024/wfs/v1_0"
KAD_WFS = "https://service.pdok.nl/kadaster/kadastralekaart/wfs/v5_0"
NWB_WFS = "https://service.pdok.nl/rws/nwbwegen/wfs/v1_0"
OPEN_METEO = "https://api.open-meteo.com/v1"


def _get_json(url: str, timeout: int = 25) -> Any:
    req = Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _bbox(lat: float, lon: float, d: float) -> str:
    # PDOK BAG/CBS praktijk: lat,lon order in bbox voor EPSG:4326
    return f"{lat - d},{lon - d},{lat + d},{lon + d},EPSG:4326"


def _wfs_features(base: str, type_names: str, lat: float, lon: float, d: float, count: int = 3) -> list:
    params = {
        "service": "WFS",
        "version": "2.0.0",
        "request": "GetFeature",
        "typeNames": type_names,
        "count": count,
        "outputFormat": "json",
        "srsName": "EPSG:4326",
        "bbox": _bbox(lat, lon, d),
    }
    data = _get_json(f"{base}?{urlencode(params)}")
    return data.get("features") or []


def _clean(v):
    if v in (-99997, -99995, -99991, -99999, None, ""):
        return None
    return v


def haal_cbs_buurt(lat: float, lon: float) -> Optional[dict]:
    feats = _wfs_features(CBS_WFS, "wijkenbuurten:buurten", lat, lon, 0.002, 1)
    if not feats:
        return None
    p = feats[0].get("properties") or {}
    return {
        "bron": "CBS Wijken en Buurten 2024 (PDOK WFS)",
        "buurtnaam": p.get("buurtnaam"),
        "buurtcode": p.get("buurtcode"),
        "wijkcode": p.get("wijkcode"),
        "gemeentenaam": p.get("gemeentenaam"),
        "gemeentecode": p.get("gemeentecode"),
        "postcode": p.get("meestVoorkomendePostcode"),
        "inwoners": _clean(p.get("aantalInwoners")),
        "huishoudens": _clean(p.get("aantalHuishoudens")),
        "bevolkingsdichtheid": _clean(p.get("bevolkingsdichtheidInwonersPerKm2")),
        "omgevingsadressendichtheid": _clean(p.get("omgevingsadressendichtheid")),
        "stedelijkheid": _clean(p.get("stedelijkheidAdressenPerKm2")),
        "gemiddelde_woningwaarde_k": _clean(p.get("gemiddeldeWoningwaarde")),  # x €1000
        "perc_koopwoningen": _clean(p.get("percentageKoopwoningen")),
        "perc_huurwoningen": _clean(p.get("percentageHuurwoningen")),
        "perc_bouwjaar_ouder_10j": _clean(p.get("percBouwjaarMeerDan10JaarGeleden")),
        "perc_aardgaswoningen": _clean(p.get("percentageAardgaswoningen")),
        "perc_aardgasvrij": _clean(p.get("percentageAardgasvrijeWoningen")),
        "gem_aardgasverbruik": _clean(p.get("gemiddeldAardgasverbruik")),
        "gem_elektriciteit": _clean(p.get("gemiddeldeElektriciteitslevering")),
        "bedrijfsvestigingen": _clean(p.get("aantalBedrijfsvestigingen")),
        "bedrijven_handel_horeca": _clean(p.get("aantalBedrijvenHandelEnHoreca")),
        "bedrijven_nijverheid": _clean(p.get("aantalBedrijvenNijverheidEnergie")),
        "niet_woningvoorraad": _clean(p.get("aantalNietWoningvoorraad")),
        "afstand_brandweer_km": _clean(p.get("brandweerkazerneGemiddeldeAfstandInKm")),
        "afstand_ziekenhuis_km": _clean(p.get("ziekenhuisExclBuitenpolikliniekGemAfstInKm")),
        "afstand_huisartsenpost_km": _clean(p.get("huisartsenpostGemiddeldeAfstandInKm")),
        "afstand_oprit_km": _clean(p.get("opritHoofdverkeerswegGemiddeldeAfstandInKm")),
        "afstand_treinstation_km": _clean(p.get("treinstationGemiddeldeAfstandInKm")),
        "oppervlakte_land_ha": _clean(p.get("oppervlakteLandInHa")),
        "oppervlakte_water_ha": _clean(p.get("oppervlakteWaterInHa")),
    }


def haal_perceel(lat: float, lon: float) -> Optional[dict]:
    feats = _wfs_features(KAD_WFS, "kadastralekaart:Perceel", lat, lon, 0.0004, 3)
    if not feats:
        return None
    # kies grootste / eerste geldige
    best = max(feats, key=lambda f: float((f.get("properties") or {}).get("kadastraleGrootteWaarde") or 0))
    p = best.get("properties") or {}
    return {
        "bron": "Kadaster Kadastrale Kaart (PDOK WFS)",
        "kadastrale_gemeente": p.get("kadastraleGemeenteWaarde") or p.get("AKRKadastraleGemeenteCodeWaarde"),
        "sectie": p.get("sectie"),
        "perceelnummer": p.get("perceelnummer"),
        "grootte_m2": _clean(p.get("kadastraleGrootteWaarde")),
        "status": p.get("statusHistorieWaarde"),
        "identificatie": p.get("identificatieLokaalID"),
    }


def haal_wegen(lat: float, lon: float) -> dict:
    feats = _wfs_features(NWB_WFS, "nwbwegen:wegvakken", lat, lon, 0.0012, 8)
    roads = []
    for f in feats:
        p = f.get("properties") or {}
        roads.append(
            {
                "straat": p.get("sttNaam"),
                "plaats": p.get("wpsnaam") or p.get("gmeNaam"),
                "wegbeheerder": p.get("wegbehnaam") or p.get("wegbehsrt"),
                "rijrichting": p.get("rijrichtng"),
                "bst_code": p.get("bstCode"),
            }
        )
    # Unieke straatnamen
    names = []
    for r in roads:
        if r["straat"] and r["straat"] not in names:
            names.append(r["straat"])
    return {
        "bron": "RWS NWB Wegen (PDOK WFS)",
        "aantal_wegvakken": len(roads),
        "straten": names[:8],
        "bereikbaarheid_indicatie": (
            "Goed — meerdere openbare wegvakken nabij"
            if len(names) >= 2
            else "Beperkt — weinig wegvakken in directe omgeving; controleer TS-toegang"
            if len(names) == 1
            else "Onbekend — geen NWB-wegvakken gevonden"
        ),
        "details": roads[:5],
    }


def haal_weer_en_hoogte(lat: float, lon: float) -> dict:
    elev = _get_json(f"{OPEN_METEO}/elevation?latitude={lat}&longitude={lon}")
    forecast = _get_json(
        f"{OPEN_METEO}/forecast?latitude={lat}&longitude={lon}"
        f"&daily=precipitation_sum,wind_speed_10m_max,wind_gusts_10m_max"
        f"&forecast_days=7&timezone=Europe%2FAmsterdam&wind_speed_unit=kmh"
    )
    daily = forecast.get("daily") or {}
    rains = daily.get("precipitation_sum") or []
    winds = daily.get("wind_speed_10m_max") or []
    gusts = daily.get("wind_gusts_10m_max") or []
    elevation = (elev.get("elevation") or [None])[0]

    max_rain = max(rains) if rains else None
    max_wind = max(winds) if winds else None
    max_gust = max(gusts) if gusts else None

    # Eenvoudige risico-indicaties (geen officiële classificatie)
    water_ind = "laag"
    if max_rain is not None:
        if max_rain >= 25:
            water_ind = "hoog"
        elif max_rain >= 10:
            water_ind = "middel"

    storm_ind = "laag"
    if max_gust is not None:
        if max_gust >= 90:
            storm_ind = "hoog"
        elif max_gust >= 60:
            storm_ind = "middel"

    flood_proxy = "laag"
    if elevation is not None:
        if elevation < 1:
            flood_proxy = "hoog"
        elif elevation < 5:
            flood_proxy = "middel"

    return {
        "bron": "Open-Meteo (elevation + forecast)",
        "elevation_m": elevation,
        "max_neerslag_7d_mm": max_rain,
        "max_wind_7d_kmh": max_wind,
        "max_windstoten_7d_kmh": max_gust,
        "water_neerslag_indicatie": water_ind,
        "storm_indicatie": storm_ind,
        "overstroming_hoogte_proxy": flood_proxy,
        "dagen": [
            {
                "datum": daily.get("time", [None])[i] if daily.get("time") else None,
                "neerslag_mm": rains[i] if i < len(rains) else None,
                "wind_kmh": winds[i] if i < len(winds) else None,
                "stoten_kmh": gusts[i] if i < len(gusts) else None,
            }
            for i in range(min(7, len(daily.get("time") or [])))
        ],
        "toelichting": (
            "Hoogte is een proxy voor wateroverlast/overstroming — geen officiële LIWO-kaart. "
            "Wind/neerslag = 7-daagse forecast, nuttig voor inspectieplanning en acute blootstelling."
        ),
    }


def verzamel_extra(lat: float, lon: float) -> dict:
    out: dict[str, Any] = {"lat": lat, "lon": lon, "errors": []}
    for name, fn in (
        ("cbs", haal_cbs_buurt),
        ("perceel", haal_perceel),
        ("wegen", haal_wegen),
        ("weer", haal_weer_en_hoogte),
    ):
        try:
            out[name] = fn(lat, lon)
        except Exception as e:
            out[name] = None
            out["errors"].append({name: str(e)})
    return out
