/**
 * Open data clients for RisicoScan (browser / lokaal)
 * - PDOK Locatieserver (BAG-adressen)
 * - PDOK BAG WFS (pand: bouwjaar, gebruiksdoel, oppervlakte)
 * - Nominatim / OSM (brandweerkazernes in de buurt)
 */

const OpenData = (() => {
  const PDOK_FREE = 'https://api.pdok.nl/bzk/locatieserver/search/v3_1/free';
  const PDOK_LOOKUP = 'https://api.pdok.nl/bzk/locatieserver/search/v3_1/lookup';
  const BAG_WFS = 'https://service.pdok.nl/lv/bag/wfs/v2_0';
  const NOMINATIM = 'https://nominatim.openstreetmap.org/search';
  const UA = 'RisicoScanLocal/1.0 (lokaal risicodeskundige tool)';

  function parsePoint(wkt) {
    // POINT(lon lat)
    const m = /POINT\(([-\d.]+)\s+([-\d.]+)\)/i.exec(wkt || '');
    if (!m) return null;
    return { lon: parseFloat(m[1]), lat: parseFloat(m[2]) };
  }

  function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const toRad = d => (d * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  async function zoekAdres(postcode, huisnummer) {
    const pc = (postcode || '').replace(/\s+/g, '').toUpperCase();
    const hn = String(huisnummer || '').trim();
    const q = hn ? `${pc} ${hn}` : pc;
    const url = `${PDOK_FREE}?q=${encodeURIComponent(q)}&fq=type:adres&rows=5`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`PDOK locatieserver HTTP ${res.status}`);
    const data = await res.json();
    const docs = data.response?.docs || [];
    if (!docs.length) {
      // fallback: postcode only
      const res2 = await fetch(`${PDOK_FREE}?q=${encodeURIComponent(pc)}&rows=3`);
      const data2 = await res2.json();
      const d2 = data2.response?.docs?.[0];
      if (!d2) throw new Error('Adres niet gevonden in BAG/PDOK');
      return normalizeLocatie(d2, { bron: 'PDOK-postcode', exact: false });
    }
    // Prefer exact house number match
    let doc = docs.find(d => String(d.huisnummer) === hn) || docs[0];
    // Enrich via lookup
    try {
      const look = await fetch(`${PDOK_LOOKUP}?id=${encodeURIComponent(doc.id)}`);
      if (look.ok) {
        const ld = await look.json();
        if (ld.response?.docs?.[0]) doc = ld.response.docs[0];
      }
    } catch (_) { /* ignore */ }
    return normalizeLocatie(doc, { bron: 'PDOK-BAG', exact: true });
  }

  function normalizeLocatie(doc, meta) {
    const coords = parsePoint(doc.centroide_ll);
    return {
      weergavenaam: doc.weergavenaam,
      postcode: doc.postcode,
      huisnummer: doc.huisnummer ?? doc.huis_nlt,
      straatnaam: doc.straatnaam,
      woonplaats: doc.woonplaatsnaam,
      gemeente: doc.gemeentenaam,
      provincie: doc.provincienaam,
      buurt: doc.buurtnaam,
      wijk: doc.wijknaam,
      waterschap: doc.waterschapsnaam,
      perceel: doc.gekoppeld_perceel || [],
      adresseerbaarobject_id: doc.adresseerbaarobject_id,
      nummeraanduiding_id: doc.nummeraanduiding_id,
      lat: coords?.lat ?? null,
      lon: coords?.lon ?? null,
      bron: meta.bron,
      exact: meta.exact
    };
  }

  async function haalPand(lat, lon) {
    if (lat == null || lon == null) return null;
    // PDOK BAG WFS uses lat,lon order in bbox for EPSG:4326 in practice
    const d = 0.0012;
    const bbox = `${lat - d},${lon - d},${lat + d},${lon + d},EPSG:4326`;
    const url =
      `${BAG_WFS}?service=WFS&version=2.0.0&request=GetFeature` +
      `&typeNames=bag:pand&count=8&outputFormat=json&srsName=EPSG:4326&bbox=${bbox}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`BAG WFS HTTP ${res.status}`);
    const data = await res.json();
    const features = data.features || [];
    if (!features.length) return null;

    // Pick feature whose centroid is closest
    let best = null;
    let bestDist = Infinity;
    for (const f of features) {
      const g = f.geometry;
      let clat = lat, clon = lon;
      if (g?.type === 'Polygon' && g.coordinates?.[0]?.[0]) {
        const ring = g.coordinates[0];
        clon = ring.reduce((s, c) => s + c[0], 0) / ring.length;
        clat = ring.reduce((s, c) => s + c[1], 0) / ring.length;
      }
      const dist = haversineKm(lat, lon, clat, clon);
      if (dist < bestDist) {
        bestDist = dist;
        best = f;
      }
    }
    const p = best.properties || {};
    return {
      identificatie: p.identificatie,
      bouwjaar: p.bouwjaar || null,
      status: p.status || null,
      gebruiksdoel: p.gebruiksdoel ? String(p.gebruiksdoel).split(',') : [],
      oppervlakte_min: p.oppervlakte_min ?? null,
      oppervlakte_max: p.oppervlakte_max ?? null,
      aantal_verblijfsobjecten: p.aantal_verblijfsobjecten ?? null,
      afstand_m: Math.round(bestDist * 1000),
      bron: 'PDOK-BAG-WFS'
    };
  }

  function enrichStation(lat, lon, s, bron) {
    const distance = haversineKm(lat, lon, s.lat, s.lon);
    const type = s.type || 'vrijwilligers';
    const turnout = type === 'beroeps' ? 2 : 5;
    const speed = type === 'beroeps' ? 55 : 45;
    const duration = Math.round((distance / speed) * 60 + turnout);
    return {
      name: s.name || 'Brandweerkazerne',
      address: s.address || s.display_name || '',
      lat: s.lat,
      lon: s.lon,
      distance_km: Math.round(distance * 10) / 10,
      duration_min: duration,
      type,
      osm_id: s.osm_id,
      bron
    };
  }

  async function loadCuratedKazernes() {
    try {
      const res = await fetch('data/kazernes-nl.json');
      if (!res.ok) return [];
      return await res.json();
    } catch (_) {
      return [];
    }
  }

  async function zoekBrandweer(lat, lon, radiusKm = 15) {
    if (lat == null || lon == null) return [];
    const dLat = radiusKm / 111;
    const dLon = radiusKm / (111 * Math.cos((lat * Math.PI) / 180));
    const viewbox = `${lon - dLon},${lat + dLat},${lon + dLon},${lat - dLat}`;

    let osm = [];
    try {
      const url =
        `${NOMINATIM}?q=${encodeURIComponent('brandweerkazerne')}` +
        `&countrycodes=nl&format=json&limit=12&viewbox=${viewbox}&bounded=1`;
      const res = await fetch(url, { headers: { Accept: 'application/json', 'User-Agent': UA } });
      if (res.ok) {
        const rows = await res.json();
        osm = rows
          .filter(r => r.type === 'fire_station' || /brandweer/i.test(r.name || r.display_name || ''))
          .map(r => enrichStation(lat, lon, {
            name: r.name,
            address: r.display_name,
            lat: parseFloat(r.lat),
            lon: parseFloat(r.lon),
            type: /amsterdam|rotterdam|den haag|utrecht|eindhoven/i.test(r.display_name || '') ? 'beroeps' : 'vrijwilligers',
            osm_id: r.osm_id
          }, 'OpenStreetMap/Nominatim'));
      }
    } catch (_) { /* fallback curated */ }

    const curated = (await loadCuratedKazernes())
      .map(s => enrichStation(lat, lon, s, 'Curated NL kazernes (aanvulling OSM)'))
      .filter(s => s.distance_km <= radiusKm);

    // Merge by rounded lat/lon to avoid duplicates
    const key = s => `${s.lat.toFixed(3)},${s.lon.toFixed(3)}`;
    const map = new Map();
    [...curated, ...osm].forEach(s => {
      const k = key(s);
      if (!map.has(k) || map.get(k).distance_km > s.distance_km) map.set(k, s);
    });
    return [...map.values()].sort((a, b) => a.distance_km - b.distance_km);
  }

  function schatWatervoorziening(lat, lon, stedelijk = true) {
    // Geen betrouwbare open hydrant-API zonder Overpass; geef onderbouwde schatting
    return {
      bron: 'schatting (geen live hydrant-API)',
      items: [
        {
          type: 'Brandkraan (verwacht)',
          location: 'Openbare weg nabij pand',
          distance: stedelijk ? '15–50 m' : '50–150 m',
          capacity: 'ca. 30–90 m³/uur (afhankelijk van leidingnet)',
          accessibility: 'Te verifiëren op locatie',
          zekerheid: 'laag'
        },
        {
          type: 'Tweede bluswatervoorziening',
          location: 'Volgende hydrant / open water',
          distance: stedelijk ? '80–200 m' : 'variabel',
          capacity: 'Onbekend',
          accessibility: 'Controleer bereikbaarheid voor TS',
          zekerheid: 'laag'
        }
      ],
      aandacht: [
        'Controleer hydrantkaart veiligheidsregio / drinkwaterbedrijf',
        'Noteer diameter, druk en obstakels (geparkeerde auto’s, steeg)',
        'Bij industrie: eigen bluswater / bassin / sprinklervoorraad'
      ]
    };
  }

  function opkomstRisicoklasse(distanceKm, durationMin) {
    // Indicatief t.o.v. Nederlandse opkomstnormen (contextueel, geen juridische toets)
    if (durationMin <= 8 && distanceKm < 4) return 'Laag';
    if (durationMin <= 12 && distanceKm < 7) return 'Gemiddeld';
    return 'Hoog';
  }

  return {
    zoekAdres,
    haalPand,
    zoekBrandweer,
    schatWatervoorziening,
    opkomstRisicoklasse,
    haversineKm
  };
})();
