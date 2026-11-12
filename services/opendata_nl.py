"""
Nederlandse open data voor RisicoScan.
- PDOK Locatieserver (BAG-adressen)
- PDOK BAG WFS (pandkenmerken)
- Nominatim/OSM (brandweerkazernes)
"""

from __future__ import annotations

import math
import re
from typing import Any, Optional
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import json

UA = "RisicoScanLocal/1.0 (risicodeskundige tool)"
PDOK_FREE = "https://api.pdok.nl/bzk/locatieserver/search/v3_1/free"
PDOK_LOOKUP = "https://api.pdok.nl/bzk/locatieserver/search/v3_1/lookup"
BAG_WFS = "https://service.pdok.nl/lv/bag/wfs/v2_0"
NOMINATIM = "https://nominatim.openstreetmap.org/search"


def _get_json(url: str, timeout: int = 20) -> Any:
    req = Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def _parse_point(wkt: Optional[str]) -> Optional[dict]:
    if not wkt:
        return None
    m = re.search(r"POINT\(([-\d.]+)\s+([-\d.]+)\)", wkt, re.I)
    if not m:
        return None
    return {"lon": float(m.group(1)), "lat": float(m.group(2))}


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def zoek_adres(postcode: str, huisnummer: str) -> dict:
    pc = re.sub(r"\s+", "", postcode or "").upper()
    hn = str(huisnummer or "").strip()
    q = f"{pc} {hn}".strip()
    data = _get_json(f"{PDOK_FREE}?{urlencode({'q': q, 'fq': 'type:adres', 'rows': 5})}")
    docs = data.get("response", {}).get("docs") or []
    if not docs:
        data = _get_json(f"{PDOK_FREE}?{urlencode({'q': pc, 'rows': 3})}")
        docs = data.get("response", {}).get("docs") or []
        if not docs:
            raise ValueError("Adres niet gevonden in BAG/PDOK")
        return _normalize(docs[0], bron="PDOK-postcode", exact=False)

    doc = next((d for d in docs if str(d.get("huisnummer")) == hn), docs[0])
    try:
        look = _get_json(f"{PDOK_LOOKUP}?{urlencode({'id': doc['id']})}")
        if look.get("response", {}).get("docs"):
            doc = look["response"]["docs"][0]
    except Exception:
        pass
    return _normalize(doc, bron="PDOK-BAG", exact=True)


def _normalize(doc: dict, bron: str, exact: bool) -> dict:
    coords = _parse_point(doc.get("centroide_ll"))
    return {
        "weergavenaam": doc.get("weergavenaam"),
        "postcode": doc.get("postcode"),
        "huisnummer": doc.get("huisnummer") or doc.get("huis_nlt"),
        "straatnaam": doc.get("straatnaam"),
        "woonplaats": doc.get("woonplaatsnaam"),
        "gemeente": doc.get("gemeentenaam"),
        "provincie": doc.get("provincienaam"),
        "buurt": doc.get("buurtnaam"),
        "wijk": doc.get("wijknaam"),
        "waterschap": doc.get("waterschapsnaam"),
        "perceel": doc.get("gekoppeld_perceel") or [],
        "adresseerbaarobject_id": doc.get("adresseerbaarobject_id"),
        "nummeraanduiding_id": doc.get("nummeraanduiding_id"),
        "lat": coords["lat"] if coords else None,
        "lon": coords["lon"] if coords else None,
        "bron": bron,
        "exact": exact,
    }


def haal_pand(lat: float, lon: float) -> Optional[dict]:
    d = 0.0012
    bbox = f"{lat - d},{lon - d},{lat + d},{lon + d},EPSG:4326"
    params = {
        "service": "WFS",
        "version": "2.0.0",
        "request": "GetFeature",
        "typeNames": "bag:pand",
        "count": 8,
        "outputFormat": "json",
        "srsName": "EPSG:4326",
        "bbox": bbox,
    }
    data = _get_json(f"{BAG_WFS}?{urlencode(params)}")
    features = data.get("features") or []
    if not features:
        return None

    best = None
    best_dist = float("inf")
    for f in features:
        g = f.get("geometry") or {}
        clat, clon = lat, lon
        if g.get("type") == "Polygon" and g.get("coordinates"):
            ring = g["coordinates"][0]
            clon = sum(c[0] for c in ring) / len(ring)
            clat = sum(c[1] for c in ring) / len(ring)
        dist = haversine_km(lat, lon, clat, clon)
        if dist < best_dist:
            best_dist = dist
            best = f

    p = (best or {}).get("properties") or {}
    doelen = p.get("gebruiksdoel")
    if isinstance(doelen, str):
        doelen = [x.strip() for x in doelen.split(",") if x.strip()]
    return {
        "identificatie": p.get("identificatie"),
        "bouwjaar": p.get("bouwjaar"),
        "status": p.get("status"),
        "gebruiksdoel": doelen or [],
        "oppervlakte_min": p.get("oppervlakte_min"),
        "oppervlakte_max": p.get("oppervlakte_max"),
        "aantal_verblijfsobjecten": p.get("aantal_verblijfsobjecten"),
        "afstand_m": round(best_dist * 1000),
        "bron": "PDOK-BAG-WFS",
    }


def _enrich_station(lat: float, lon: float, s: dict, bron: str) -> dict:
    distance = haversine_km(lat, lon, float(s["lat"]), float(s["lon"]))
    stype = s.get("type") or "vrijwilligers"
    turnout = 2 if stype == "beroeps" else 5
    speed = 55 if stype == "beroeps" else 45
    duration = round((distance / speed) * 60 + turnout)
    return {
        "name": s.get("name") or "Brandweerkazerne",
        "address": s.get("address") or s.get("display_name") or "",
        "lat": float(s["lat"]),
        "lon": float(s["lon"]),
        "distance_km": round(distance, 1),
        "duration_min": duration,
        "type": stype,
        "osm_id": s.get("osm_id"),
        "bron": bron,
    }


def _load_curated_kazernes() -> list:
    import os
    for path in (
        os.path.join(os.path.dirname(__file__), "kazernes-nl.json"),
        os.path.join(os.path.dirname(__file__), "..", "lokaal-demo", "data", "kazernes-nl.json"),
    ):
        try:
            with open(path, encoding="utf-8") as f:
                return json.load(f)
        except OSError:
            continue
    return []


def zoek_brandweer(lat: float, lon: float, radius_km: float = 15.0) -> list:
    d_lat = radius_km / 111.0
    d_lon = radius_km / (111.0 * max(0.2, math.cos(math.radians(lat))))
    viewbox = f"{lon - d_lon},{lat + d_lat},{lon + d_lon},{lat - d_lat}"
    params = {
        "q": "brandweerkazerne",
        "countrycodes": "nl",
        "format": "json",
        "limit": 12,
        "viewbox": viewbox,
        "bounded": 1,
    }
    osm = []
    try:
        rows = _get_json(f"{NOMINATIM}?{urlencode(params)}")
        for r in rows:
            name = r.get("name") or ""
            display = r.get("display_name") or ""
            if r.get("type") != "fire_station" and "brandweer" not in (name + display).lower():
                continue
            big_city = any(
                c in display.lower()
                for c in ("amsterdam", "rotterdam", "den haag", "utrecht", "eindhoven", "'s-gravenhage")
            )
            osm.append(
                _enrich_station(
                    lat,
                    lon,
                    {
                        "name": name or "Brandweerkazerne",
                        "address": display,
                        "lat": float(r["lat"]),
                        "lon": float(r["lon"]),
                        "type": "beroeps" if big_city else "vrijwilligers",
                        "osm_id": r.get("osm_id"),
                    },
                    "OpenStreetMap/Nominatim",
                )
            )
    except Exception:
        osm = []

    curated = [
        _enrich_station(lat, lon, s, "Curated NL kazernes (aanvulling OSM)")
        for s in _load_curated_kazernes()
    ]
    curated = [s for s in curated if s["distance_km"] <= radius_km]

    merged = {}
    for s in curated + osm:
        key = f"{s['lat']:.3f},{s['lon']:.3f}"
        if key not in merged or merged[key]["distance_km"] > s["distance_km"]:
            merged[key] = s
    stations = list(merged.values())
    stations.sort(key=lambda s: s["distance_km"])
    return stations


def schat_watervoorziening(stedelijk: bool = True) -> dict:
    return {
        "bron": "schatting (geen live hydrant-API; Overpass niet beschikbaar)",
        "items": [
            {
                "type": "Brandkraan (verwacht)",
                "location": "Openbare weg nabij pand",
                "distance": "15–50 m" if stedelijk else "50–150 m",
                "capacity": "ca. 30–90 m³/uur",
                "accessibility": "Te verifiëren op locatie",
                "zekerheid": "laag",
            },
            {
                "type": "Tweede bluswatervoorziening",
                "location": "Volgende hydrant / open water",
                "distance": "80–200 m" if stedelijk else "variabel",
                "capacity": "Onbekend",
                "accessibility": "Controleer bereikbaarheid voor TS",
                "zekerheid": "laag",
            },
        ],
        "aandacht": [
            "Controleer hydrantkaart veiligheidsregio / drinkwaterbedrijf",
            "Noteer diameter, druk en obstakels",
            "Bij industrie: eigen bluswater / bassin / sprinklervoorraad",
        ],
    }


def opkomst_risicoklasse(distance_km: float, duration_min: int) -> str:
    if duration_min <= 8 and distance_km < 4:
        return "Laag"
    if duration_min <= 12 and distance_km < 7:
        return "Gemiddeld"
    return "Hoog"


def volledige_locatie_analyse(postcode: str, huisnummer: str) -> dict:
    locatie = zoek_adres(postcode, huisnummer)
    pand = None
    brandweer = []
    extra = None
    if locatie.get("lat") is not None:
        try:
            pand = haal_pand(locatie["lat"], locatie["lon"])
        except Exception as e:
            pand = {"error": str(e)}
        try:
            brandweer = zoek_brandweer(locatie["lat"], locatie["lon"])
        except Exception as e:
            brandweer = [{"error": str(e)}]
        try:
            from services.extra_apis import verzamel_extra

            extra = verzamel_extra(locatie["lat"], locatie["lon"])
        except Exception as e:
            extra = {"error": str(e)}
    stedelijk = True
    if extra and isinstance(extra.get("cbs"), dict):
        oad = extra["cbs"].get("omgevingsadressendichtheid")
        if isinstance(oad, (int, float)):
            stedelijk = oad >= 1500
    water = schat_watervoorziening(stedelijk=stedelijk)
    nearest = brandweer[0] if brandweer and "error" not in brandweer[0] else None
    risk = (
        opkomst_risicoklasse(nearest["distance_km"], nearest["duration_min"])
        if nearest
        else "Onbekend"
    )
    return {
        "locatie": locatie,
        "pand": pand,
        "brandweer": brandweer,
        "water": water,
        "opkomst_risicoklasse": risk,
        "extra": extra,
    }
