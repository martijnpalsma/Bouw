/**
 * Extra open APIs voor risk engineer (browser)
 * CBS buurten, Kadaster perceel, NWB wegen, Open-Meteo
 */
const ExtraApis = (() => {
  const CBS = 'https://service.pdok.nl/cbs/wijkenbuurten/2024/wfs/v1_0';
  const KAD = 'https://service.pdok.nl/kadaster/kadastralekaart/wfs/v5_0';
  const NWB = 'https://service.pdok.nl/rws/nwbwegen/wfs/v1_0';
  const METEO = 'https://api.open-meteo.com/v1';

  function bbox(lat, lon, d) {
    return `${lat - d},${lon - d},${lat + d},${lon + d},EPSG:4326`;
  }

  async function wfs(base, typeNames, lat, lon, d, count = 3) {
    const params = new URLSearchParams({
      service: 'WFS', version: '2.0.0', request: 'GetFeature',
      typeNames, count: String(count), outputFormat: 'json',
      srsName: 'EPSG:4326', bbox: bbox(lat, lon, d)
    });
    const res = await fetch(`${base}?${params}`);
    if (!res.ok) throw new Error(`WFS ${res.status}`);
    const data = await res.json();
    return data.features || [];
  }

  function clean(v) {
    if (v === -99997 || v === -99995 || v === -99991 || v === -99999 || v == null || v === '') return null;
    return v;
  }

  async function cbsBuurt(lat, lon) {
    const feats = await wfs(CBS, 'wijkenbuurten:buurten', lat, lon, 0.002, 1);
    if (!feats.length) return null;
    const p = feats[0].properties || {};
    return {
      bron: 'CBS Wijken en Buurten 2024 (PDOK WFS)',
      buurtnaam: p.buurtnaam,
      buurtcode: p.buurtcode,
      wijkcode: p.wijkcode,
      gemeentenaam: p.gemeentenaam,
      inwoners: clean(p.aantalInwoners),
      huishoudens: clean(p.aantalHuishoudens),
      bevolkingsdichtheid: clean(p.bevolkingsdichtheidInwonersPerKm2),
      omgevingsadressendichtheid: clean(p.omgevingsadressendichtheid),
      stedelijkheid: clean(p.stedelijkheidAdressenPerKm2),
      gemiddelde_woningwaarde_k: clean(p.gemiddeldeWoningwaarde),
      perc_koopwoningen: clean(p.percentageKoopwoningen),
      perc_huurwoningen: clean(p.percentageHuurwoningen),
      perc_bouwjaar_ouder_10j: clean(p.percBouwjaarMeerDan10JaarGeleden),
      perc_aardgaswoningen: clean(p.percentageAardgaswoningen),
      perc_aardgasvrij: clean(p.percentageAardgasvrijeWoningen),
      gem_aardgasverbruik: clean(p.gemiddeldAardgasverbruik),
      gem_elektriciteit: clean(p.gemiddeldeElektriciteitslevering),
      bedrijfsvestigingen: clean(p.aantalBedrijfsvestigingen),
      bedrijven_handel_horeca: clean(p.aantalBedrijvenHandelEnHoreca),
      bedrijven_nijverheid: clean(p.aantalBedrijvenNijverheidEnergie),
      niet_woningvoorraad: clean(p.aantalNietWoningvoorraad),
      afstand_brandweer_km: clean(p.brandweerkazerneGemiddeldeAfstandInKm),
      afstand_ziekenhuis_km: clean(p.ziekenhuisExclBuitenpolikliniekGemAfstInKm),
      afstand_huisartsenpost_km: clean(p.huisartsenpostGemiddeldeAfstandInKm),
      afstand_oprit_km: clean(p.opritHoofdverkeerswegGemiddeldeAfstandInKm),
      afstand_treinstation_km: clean(p.treinstationGemiddeldeAfstandInKm),
      oppervlakte_water_ha: clean(p.oppervlakteWaterInHa)
    };
  }

  async function perceel(lat, lon) {
    const feats = await wfs(KAD, 'kadastralekaart:Perceel', lat, lon, 0.0004, 3);
    if (!feats.length) return null;
    const best = feats.reduce((a, b) =>
      (Number(b.properties?.kadastraleGrootteWaarde || 0) > Number(a.properties?.kadastraleGrootteWaarde || 0) ? b : a)
    );
    const p = best.properties || {};
    return {
      bron: 'Kadaster Kadastrale Kaart (PDOK WFS)',
      kadastrale_gemeente: p.kadastraleGemeenteWaarde || p.AKRKadastraleGemeenteCodeWaarde,
      sectie: p.sectie,
      perceelnummer: p.perceelnummer,
      grootte_m2: clean(p.kadastraleGrootteWaarde),
      status: p.statusHistorieWaarde
    };
  }

  async function wegen(lat, lon) {
    const feats = await wfs(NWB, 'nwbwegen:wegvakken', lat, lon, 0.0012, 8);
    const names = [];
    const details = [];
    for (const f of feats) {
      const p = f.properties || {};
      details.push({ straat: p.sttNaam, plaats: p.wpsnaam || p.gmeNaam, wegbeheerder: p.wegbehnaam || p.wegbehsrt });
      if (p.sttNaam && !names.includes(p.sttNaam)) names.push(p.sttNaam);
    }
    return {
      bron: 'RWS NWB Wegen (PDOK WFS)',
      aantal_wegvakken: feats.length,
      straten: names.slice(0, 8),
      bereikbaarheid_indicatie: names.length >= 2
        ? 'Goed — meerdere openbare wegvakken nabij'
        : names.length === 1
          ? 'Beperkt — weinig wegvakken; controleer TS-toegang'
          : 'Onbekend — geen NWB-wegvakken gevonden',
      details: details.slice(0, 5)
    };
  }

  async function weerHoogte(lat, lon) {
    const elev = await (await fetch(`${METEO}/elevation?latitude=${lat}&longitude=${lon}`)).json();
    const forecast = await (await fetch(
      `${METEO}/forecast?latitude=${lat}&longitude=${lon}` +
      `&daily=precipitation_sum,wind_speed_10m_max,wind_gusts_10m_max` +
      `&forecast_days=7&timezone=Europe%2FAmsterdam&wind_speed_unit=kmh`
    )).json();
    const daily = forecast.daily || {};
    const rains = daily.precipitation_sum || [];
    const winds = daily.wind_speed_10m_max || [];
    const gusts = daily.wind_gusts_10m_max || [];
    const elevation = (elev.elevation || [null])[0];
    const maxRain = rains.length ? Math.max(...rains) : null;
    const maxWind = winds.length ? Math.max(...winds) : null;
    const maxGust = gusts.length ? Math.max(...gusts) : null;

    const waterInd = maxRain == null ? 'laag' : maxRain >= 25 ? 'hoog' : maxRain >= 10 ? 'middel' : 'laag';
    const stormInd = maxGust == null ? 'laag' : maxGust >= 90 ? 'hoog' : maxGust >= 60 ? 'middel' : 'laag';
    const floodProxy = elevation == null ? 'onbekend' : elevation < 1 ? 'hoog' : elevation < 5 ? 'middel' : 'laag';

    return {
      bron: 'Open-Meteo (elevation + forecast)',
      elevation_m: elevation,
      max_neerslag_7d_mm: maxRain,
      max_wind_7d_kmh: maxWind,
      max_windstoten_7d_kmh: maxGust,
      water_neerslag_indicatie: waterInd,
      storm_indicatie: stormInd,
      overstroming_hoogte_proxy: floodProxy,
      dagen: (daily.time || []).slice(0, 7).map((datum, i) => ({
        datum, neerslag_mm: rains[i], wind_kmh: winds[i], stoten_kmh: gusts[i]
      })),
      toelichting: 'Hoogte = proxy (geen LIWO). Wind/neerslag = 7-daagse forecast.'
    };
  }

  async function verzamel(lat, lon) {
    const out = { lat, lon, errors: [] };
    const jobs = [
      ['cbs', () => cbsBuurt(lat, lon)],
      ['perceel', () => perceel(lat, lon)],
      ['wegen', () => wegen(lat, lon)],
      ['weer', () => weerHoogte(lat, lon)]
    ];
    await Promise.all(jobs.map(async ([name, fn]) => {
      try { out[name] = await fn(); }
      catch (e) { out[name] = null; out.errors.push({ [name]: e.message }); }
    }));
    return out;
  }

  return { verzamel, cbsBuurt, perceel, wegen, weerHoogte };
})();
