/**
 * Risico-engine voor taxateur / risicodeskundige
 * Regel: alleen harde feiten presenteren als feit.
 * Alles wat afgeleid/geschat is → zekerheid "controleer" of "schatting".
 */

const RiskEngine = (() => {
  const TOPICS = [
    { id: 'activiteiten', name: 'Bedrijfsactiviteiten', group: 'Algemeen' },
    { id: 'gebouwen', name: 'Gebouwen', group: 'Algemeen' },
    { id: 'constructie', name: 'Constructie', group: 'Bouwkundig' },
    { id: 'gevel_dak', name: 'Gevel / dak / kozijnen', group: 'Bouwkundig' },
    { id: 'compartimentering', name: 'Compartimentering', group: 'Brand' },
    { id: 'elektra', name: 'Elektrische installatie', group: 'Installaties' },
    { id: 'verwarming', name: 'Verwarming', group: 'Installaties' },
    { id: 'detectie', name: 'Branddetectie', group: 'Brand' },
    { id: 'blusmiddelen', name: 'Blusmiddelen', group: 'Brand' },
    { id: 'huishouding', name: 'Huishouding / orde & netheid', group: 'Organisatie' },
    { id: 'roken', name: 'Roken / open vuur', group: 'Brand' },
    { id: 'accus', name: "Accu's en laadplaatsen", group: 'Speciaal risico' },
    { id: 'gevaarlijk', name: 'Gevaarlijke stoffen', group: 'Speciaal risico' },
    { id: 'machines', name: 'Machines / processen', group: 'Speciaal risico' },
    { id: 'opslag', name: 'Opslag', group: 'Speciaal risico' },
    { id: 'buitenopslag', name: 'Buitenopslag', group: 'Speciaal risico' },
    { id: 'inbraak', name: 'Inbraak / diefstal', group: 'Security' },
    { id: 'water', name: 'Water (schade)', group: 'Elementair' },
    { id: 'storm', name: 'Storm', group: 'Elementair' },
    { id: 'bedrijfsschade', name: 'Bedrijfsschade / continuïteit', group: 'Taxatie' },
    { id: 'brandweer', name: 'Brandweer / repressie', group: 'Brand' },
    { id: 'ontruiming', name: 'Ontruiming / BHV', group: 'Organisatie' },
    { id: 'dakveiligheid', name: 'Dakveiligheid / zonnepanelen', group: 'Bouwkundig' },
    { id: 'sandwich', name: 'Sandwichpanelen / isolatiebrand', group: 'Brand' }
  ];

  const FUNCTIE_VRAGEN = {
    'Industrie / productie': [
      { id: 'ind_processen', text: 'Welke productieprocessen vinden plaats?', waarom: 'Bepaalt brandlast en explosierisico' },
      { id: 'ind_ploegen', text: 'Is er 24-uurs bezetting?', waarom: 'Invloed op ontdekkingstijd brand' }
    ],
    'Metaalbewerking': [
      { id: 'metal_welding', text: 'Wordt gelast, geslepen of gebrand?', waarom: 'Vonken / hete werkzaamheden' },
      { id: 'metal_gas', text: 'Zijn lasgassen aanwezig?', waarom: 'Explosie- en brandrisico' }
    ],
    'Houtbewerking': [
      { id: 'wood_dust', text: 'Is houtstofafzuiging aanwezig en onderhouden?', waarom: 'Stofexplosie / snelle branduitbreiding' }
    ],
    'Opslag / warehouse': [
      { id: 'storage_height', text: 'Tot welke hoogte wordt opgeslagen?', waarom: 'Sprinklerontwerp & branduitbreiding' },
      { id: 'storage_sprinkler', text: 'Zijn sprinklers aanwezig en passend bij opslag?', waarom: 'Kritisch voor verzekerbaarheid' },
      { id: 'storage_plastic', text: 'Hoeveel kunststof / aerosolen / pallets?', waarom: 'Brandlast en rookontwikkeling' }
    ],
    'Horeca': [
      { id: 'food_fryer', text: 'Zijn frituurinstallaties aanwezig?', waarom: 'Keukenbrand #1 oorzaak horeca' },
      { id: 'food_hood', text: 'Worden afzuigkanalen periodiek gereinigd?', waarom: 'Vetafzetting = brandversneller' }
    ],
    'Hotel': [
      { id: 'hotel_rooms', text: 'Aantal kamers / slaapplaatsen?', waarom: 'Ontruimingscomplexiteit' },
      { id: 'hotel_detection', text: 'Automatische detectie + doormelding?', waarom: 'Nachtelijke bezetting' }
    ],
    'Zorginstelling': [
      { id: 'care_self', text: 'Zijn bewoners/cliënten zelfredzaam?', waarom: 'Ontruimingsstrategie' },
      { id: 'care_evac', text: 'Hoe is ontruiming georganiseerd?', waarom: 'Levensveiligheid + aansprakelijkheid' }
    ],
    'Garage / autobedrijf': [
      { id: 'garage_ev', text: 'Worden EV’s / lithium-accu’s geladen?', waarom: 'Hoog brandrisico, lastig te blussen' },
      { id: 'garage_tires', text: 'Bandenopslag aanwezig?', waarom: 'Hoge brandlast' }
    ],
    'Winkel': [
      { id: 'shop_stock', text: 'Wat is de samenstelling van de voorraad?', waarom: 'Brandlast en rook' },
      { id: 'shop_closing', text: 'Is er alarmering buiten openingstijden?', waarom: 'Ontdekkingstijd' }
    ],
    'Kantoor': [
      { id: 'office_server', text: 'Is er een serverruimte / UPS / lithium?', waarom: 'Elektrisch brandrisico' }
    ],
    'Woning / wooncomplex': [
      { id: 'res_escape', text: 'Vluchtwegen en rookmelders per woning?', waarom: 'Levensveiligheid' }
    ]
  };

  const STANDARD_QUESTIONS = [
    { id: 'activities_main', text: 'Wat zijn de feitelijke bedrijfsactiviteiten op locatie?', waarom: 'Basis voor alle risico-inschatting' },
    { id: 'construction', text: 'Wat is de draagconstructie (beton/staal/hout/metselwerk)?', waarom: 'Brandwerendheid en instortingsgedrag' },
    { id: 'facade', text: 'Gevelbekleding en brandklasse (incl. sandwich/PIR)?', waarom: 'Gevelbrand / snelle uitbreiding' },
    { id: 'compartment', text: 'Hoe is brandcompartimentering (WBDBO) uitgevoerd?', waarom: 'Beperking branduitbreiding' },
    { id: 'electrical', text: 'Ouderdom elektra + laatste NEN 3140 / Scope 8-10 keuring?', waarom: 'Veel voorkomende brandoorzaak' },
    { id: 'heating', text: 'Type verwarming / stookruimte / gasleidingen?', waarom: 'Gas- en stookrisico' },
    { id: 'detection', text: 'Rookmelders / BMC / doormelding naar PAC?', waarom: 'Ontdekkingstijd' },
    { id: 'extinguishers', text: 'Blusmiddelen aanwezig en gekeurd?', waarom: 'Eerste interventie' },
    { id: 'accus', text: "Lithium-ion accu's of e-bikes laden op locatie?", waarom: 'Thermal runaway risico' },
    { id: 'hazmat', text: 'Gevaarlijke stoffen / ADR / gasflessen?', waarom: 'Escalatie bij brand' },
    { id: 'security', text: 'Inbraakbeveiliging (sloten, alarm, camera)?', waarom: 'Taxatie premie + diefstalschade' },
    { id: 'water_storm', text: 'Wateraccumulatie dak / kelder / stormgevoelige delen?', waarom: 'Elementaire schades' },
    { id: 'bi', text: 'Herbouwwaarde, inventariswaarde, bedrijfsschade-dekking?', waarom: 'Taxatie & verzekeringsadvies' },
    { id: 'solar', text: 'Zonnepanelen op het dak? DC-isolatoren / brandweerprocedure?', waarom: 'Blusveiligheid + dakbrand' },
    { id: 'housekeeping', text: 'Orde & netheid: afval, pallets, rookverbod?', waarom: 'Brandlast en menselijk falen' }
  ];

  function statusRank(s) {
    return { ok: 0, onbekend: 1, aandacht: 2, tekort: 3 }[s] ?? 1;
  }

  function topic(t, status, note, zekerheid = 'controleer') {
    return { id: t.id, name: t.name, group: t.group, status, note, zekerheid };
  }

  function buildReport({ locatie, pand, brandweer, water, functie, fotoHints, antwoorden, extra }) {
    extra = extra || {};
    const cbs = extra.cbs || null;
    const weer = extra.weer || null;
    const wegen = extra.wegen || null;
    const perceel = extra.perceel || null;

    const bouwjaar = pand?.bouwjaar || null;
    const age = bouwjaar ? new Date().getFullYear() - bouwjaar : null;
    const nearest = brandweer?.[0] || null;
    const riskClass = nearest
      ? OpenData.opkomstRisicoklasse(nearest.distance_km, nearest.duration_min)
      : 'Onbekend';

    const topics = TOPICS.map(t => evaluateTopic(t, {
      locatie, pand, brandweer, water, functie, fotoHints, antwoorden, bouwjaar, age, nearest, riskClass, cbs, weer, wegen
    }));

    const raw = topics.reduce((s, t) => s + statusRank(t.status), 0);
    const max = topics.length * 3;
    const score = Math.round(100 - (raw / max) * 100);
    const niveau = score >= 75 ? 'laag' : score >= 55 ? 'gemiddeld' : 'hoog';

    const vragen = buildQuestions(functie, topics);
    const tekortkomingen = topics.filter(t => t.status === 'tekort' || t.status === 'aandacht');
    const openstaand = topics.filter(t => t.status === 'onbekend');
    const feiten = topics.filter(t => t.zekerheid === 'feit');
    const teControleren = topics.filter(t => t.zekerheid !== 'feit');

    const wozK = cbs?.gemiddelde_woningwaarde_k;

    return {
      timestamp: new Date().toISOString(),
      locatie,
      pand,
      brandweer: {
        nearest,
        stations: brandweer || [],
        riskClass,
        riskClass_zekerheid: 'schatting',
        water
      },
      extra: { cbs, weer, wegen, perceel },
      functie,
      functie_zekerheid: 'controleer',
      bouwjaar,
      age,
      score,
      score_toelichting: 'Score weerspiegelt openstaande inspectiepunten, geen verzekeringsadvies.',
      niveau,
      topics,
      tekortkomingen,
      openstaand,
      feiten,
      teControleren,
      vragen,
      materialen: inferMaterials(pand, fotoHints, bouwjaar),
      taxatie: {
        herbouwwaarde_indicatie: typeof wozK === 'number'
          ? `CBS gem. woningwaarde buurt €${(wozK * 1000).toLocaleString('nl-NL')} — CONTROLEER: dit is géén herbouwwaarde van dit object`
          : 'n.n.b. — CONTROLEER bij taxateur/calculatie',
        herbouwwaarde_zekerheid: 'controleer',
        inventaris: 'n.n.b. — CONTROLEER op locatie / polis',
        inventaris_zekerheid: 'controleer',
        bedrijfsschade: 'n.n.b. — CONTROLEER omzet / max. uitkeringstermijn',
        bedrijfsschade_zekerheid: 'controleer',
        premie_drivers: teControleren.slice(0, 8).map(t => t.name),
        blootstelling: {
          bevolkingsdichtheid: cbs?.bevolkingsdichtheid ?? null,
          bedrijfsvestigingen: cbs?.bedrijfsvestigingen ?? null,
          omgevingsadressendichtheid: cbs?.omgevingsadressendichtheid ?? null,
          zekerheid: cbs ? 'feit' : 'onbekend',
          bron: cbs?.bron || null
        },
        perceel_m2: perceel?.grootte_m2 ?? null,
        perceel_zekerheid: perceel?.grootte_m2 != null ? 'feit' : 'onbekend'
      },
      bronnen: collectSources(locatie, pand, brandweer, water, extra),
      conclusie: writeConclusion({
        niveau, score, nearest, riskClass, pand, functie, openstaand, tekortkomingen, feiten, teControleren, cbs, weer
      })
    };
  }

  function evaluateTopic(t, ctx) {
    const { pand, functie, fotoHints, antwoorden, bouwjaar, age, nearest, riskClass, cbs, weer, wegen } = ctx;
    const a = antwoorden || {};
    const C = cbs || {};
    const W = weer || {};
    const R = wegen || {};

    switch (t.id) {
      case 'activiteiten':
        if (a.activities_main) return topic(t, 'ok', a.activities_main, 'feit');
        if (functie) {
          return topic(t, 'onbekend',
            `Opgegeven in formulier: “${functie}”. CONTROLEER feitelijke activiteiten op locatie — niet overgenomen als feit.`,
            'controleer');
        }
        return topic(t, 'onbekend', 'CONTROLEER: bedrijfsactiviteiten nog niet vastgelegd.', 'controleer');

      case 'gebouwen':
        if (pand) {
          return topic(t, 'ok',
            `BAG: bouwjaar ${pand.bouwjaar ?? 'n.b.'}, status ${pand.status || 'n.b.'}, VBO’s ${pand.aantal_verblijfsobjecten ?? 'n.b.'} (${pand.bron || 'BAG'}).`,
            'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: geen pand in BAG WFS voor dit punt.', 'controleer');

      case 'constructie':
        if (a.construction) return topic(t, 'ok', a.construction, 'feit');
        return topic(t, 'onbekend', 'CONTROLEER: draagconstructie (beton/staal/hout/metselwerk) — niet bekend uit open data.', 'controleer');

      case 'gevel_dak':
        if (a.facade) return topic(t, 'ok', a.facade, 'feit');
        if (fotoHints?.gevel) {
          return topic(t, 'onbekend', `CONTROLEER: ${fotoHints.gevel}`, 'controleer');
        }
        return topic(t, 'onbekend', 'CONTROLEER: gevel-/dakmateriaal en brandklasse (PIR/PUR/MW) op locatie.', 'controleer');

      case 'compartimentering':
        if (a.compartment) {
          return topic(t, a.compartment.toLowerCase().includes('geen') ? 'tekort' : 'ok', a.compartment, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: WBDBO, branddeuren, doorvoeringen — niet uit open data.', 'controleer');

      case 'elektra':
        if (a.electrical) return topic(t, 'ok', a.electrical, 'feit');
        if (age != null && age > 30) {
          return topic(t, 'onbekend',
            `BAG-bouwjaar ${bouwjaar} (feit). CONTROLEER: recente elektra-keuring (NEN 3140 / Scope) — leeftijd ≠ keuringsstatus.`,
            'controleer');
        }
        return topic(t, 'onbekend', 'CONTROLEER: elektra-keuring / ouderdom installatie.', 'controleer');

      case 'verwarming':
        if (a.heating) return topic(t, 'ok', a.heating, 'feit');
        if (typeof C.perc_aardgaswoningen === 'number') {
          return topic(t, 'onbekend',
            `CBS-buurtfeit: ${C.perc_aardgaswoningen}% aardgaswoningen (gem. ${C.gem_aardgasverbruik ?? '?'} m³). CONTROLEER type CV/gas op dí́t object — buurt≠object.`,
            'controleer');
        }
        return topic(t, 'onbekend', 'CONTROLEER: type verwarming / stookruimte / gas.', 'controleer');

      case 'detectie':
        if (a.detection) {
          const low = /geen|nee/i.test(a.detection);
          return topic(t, low ? 'tekort' : 'ok', a.detection, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: rookmelders / BMC / doormelding.', 'controleer');

      case 'blusmiddelen':
        if (a.extinguishers) {
          return topic(t, /geen|nee/i.test(a.extinguishers) ? 'tekort' : 'ok', a.extinguishers, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: handblussers / haspels / sprinkler + keuring.', 'controleer');

      case 'huishouding':
        if (a.housekeeping) {
          return topic(t, /slecht|rommel/i.test(a.housekeeping) ? 'aandacht' : 'ok', a.housekeeping, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: orde & netheid tijdens inspectie.', 'controleer');

      case 'roken':
        return topic(t, 'onbekend', 'CONTROLEER: rookbeleid, open vuur, hot-work permit.', 'controleer');

      case 'accus':
        if (a.accus) {
          return topic(t, /ja|lithium|laden/i.test(a.accus) ? 'aandacht' : 'ok', a.accus, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: lithium-ion / e-bike / EV-laden (vrije ruimte, detectie, onbeheerd laden).', 'controleer');

      case 'gevaarlijk':
        if (a.hazmat) {
          return topic(t, /ja|aanwezig/i.test(a.hazmat) ? 'aandacht' : 'ok', a.hazmat, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: ADR / stoffenlijst / gasflessen — niet afleiden uit functie alleen.', 'controleer');

      case 'machines':
        return topic(t, 'onbekend', 'CONTROLEER: machines/processen en brandlast — niet bekend uit open data.', 'controleer');

      case 'opslag':
        return topic(t, 'onbekend', 'CONTROLEER: opslaghoogte, brandlast, sprinklercompatibiliteit.', 'controleer');

      case 'buitenopslag':
        return topic(t, 'onbekend', 'CONTROLEER: afstand tot gevel, containers, pallets, gasflessen buiten.', 'controleer');

      case 'inbraak':
        if (a.security) return topic(t, 'ok', a.security, 'feit');
        return topic(t, 'onbekend', 'CONTROLEER: slotenklasse, alarm, camera (premie-relevant).', 'controleer');

      case 'water':
        if (a.water_storm) {
          return topic(t, /lekkage|overlast|accumulatie/i.test(a.water_storm) ? 'aandacht' : 'ok', a.water_storm, 'feit');
        }
        if (W.elevation_m != null || W.max_neerslag_7d_mm != null) {
          const notes = [];
          if (W.elevation_m != null) {
            notes.push(`Open-Meteo hoogte ${W.elevation_m} m (feit uit model)`);
          }
          if (W.max_neerslag_7d_mm != null) {
            notes.push(`neerslag 7d max ${W.max_neerslag_7d_mm} mm (feit)`);
          }
          notes.push('CONTROLEER: kelder/dakafvoer — overstromingslabel is PROXY, geen LIWO');
          return topic(t, 'onbekend', notes.join('. ') + '.', 'controleer');
        }
        return topic(t, 'onbekend', 'CONTROLEER: dakafvoer, kelder, leidingbreukscenario’s.', 'controleer');

      case 'storm':
        if (W.max_windstoten_7d_kmh != null) {
          return topic(t, 'onbekend',
            `Open-Meteo feit: max windstoten 7d ${W.max_windstoten_7d_kmh} km/h. CONTROLEER dak/gevel/luifels op object.`,
            'controleer');
        }
        return topic(t, 'onbekend', 'CONTROLEER: dakverankering, gevelplaten, luifels, bomen nabij.', 'controleer');

      case 'bedrijfsschade':
        if (a.bi) return topic(t, 'ok', a.bi, 'feit');
        return topic(t, 'onbekend', 'CONTROLEER: omzetafhankelijkheid, uitwijk, max. schadeperiode.', 'controleer');

      case 'brandweer': {
        if (!nearest && C.afstand_brandweer_km == null) {
          return topic(t, 'onbekend', 'CONTROLEER: geen kazerne/CBS-afstand gevonden.', 'controleer');
        }
        const parts = [];
        if (nearest) {
          parts.push(`FEIT (hemelsbreed): ${nearest.name} op ${nearest.distance_km} km (${nearest.bron || 'bron n.b.'})`);
          parts.push(`SCHATTING: opkomst ±${nearest.duration_min} min / klasse “${riskClass}” — geen officiële VR-normtoets`);
        }
        if (C.afstand_brandweer_km != null) {
          parts.push(`CBS-buurtfeit: gem. afstand brandweer ${C.afstand_brandweer_km} km`);
        }
        if (R.bereikbaarheid_indicatie) {
          parts.push(`NWB-indicatie: ${R.bereikbaarheid_indicatie} — CONTROLEER TS-toegang op locatie`);
        }
        return topic(t, 'onbekend', parts.join('. ') + '.', nearest ? 'schatting' : 'controleer');
      }

      case 'ontruiming':
        return topic(t, 'onbekend', 'CONTROLEER: BHV-organisatie en ontruimingsplattegronden.', 'controleer');

      case 'dakveiligheid':
        if (a.solar) {
          return topic(t, /ja|paneel/i.test(a.solar) ? 'aandacht' : 'ok', a.solar, 'feit');
        }
        return topic(t, 'onbekend', 'CONTROLEER: PV, ballast, doorvoeren, blusprocedure.', 'controleer');

      case 'sandwich':
        return topic(t, 'onbekend', 'CONTROLEER: kernisolatie sandwichpanelen (PIR/PUR/MW) — niet uit open data.', 'controleer');

      default:
        return topic(t, 'onbekend', 'CONTROLEER.', 'controleer');
    }
  }

  function buildQuestions(functie, topics) {
    const qs = [...STANDARD_QUESTIONS];
    const extra = FUNCTIE_VRAGEN[functie] || [];
    extra.forEach(e => qs.push({ id: e.id, text: e.text, waarom: e.waarom }));

    const unknownIds = new Set(topics.filter(t => t.zekerheid !== 'feit').map(t => t.id));
    return qs
      .map(q => ({
        vraag: q.text,
        reden: q.waarom,
        id: q.id,
        prioriteit: unknownIds.has(q.id) || /accus|compartment|detection|electrical|sprinkler|lithium/i.test(q.id + q.text)
          ? 'hoog'
          : 'normaal'
      }))
      .sort((a, b) => (a.prioriteit === 'hoog' ? 0 : 1) - (b.prioriteit === 'hoog' ? 0 : 1))
      .slice(0, 12);
  }

  function inferMaterials(pand, fotoHints, bouwjaar) {
    return {
      gevel: [{ tekst: 'Niet vastgesteld uit open data', zekerheid: 'controleer' }],
      dak: [{ tekst: 'Niet vastgesteld uit open data', zekerheid: 'controleer' }],
      kozijnen: [{ tekst: 'Niet vastgesteld uit open data', zekerheid: 'controleer' }],
      isolatie: bouwjaar
        ? [{
            tekst: `BAG-bouwjaar ${bouwjaar} (feit). Isolatieniveau CONTROLEER op object — niet afleiden uit jaartal alleen.`,
            zekerheid: 'controleer'
          }]
        : [{ tekst: 'CONTROLEER isolatie op object', zekerheid: 'controleer' }],
      gebruiksdoel_bag: (pand?.gebruiksdoel || []).map(g => ({ tekst: g, zekerheid: 'feit' })),
      foto_hint: fotoHints?.gevel
        ? [{ tekst: fotoHints.gevel, zekerheid: 'controleer' }]
        : []
    };
  }

  function collectSources(locatie, pand, brandweer, water, extra) {
    const s = [];
    if (locatie?.bron) s.push({ naam: 'Adres', detail: locatie.bron, zekerheid: 'feit' });
    if (pand?.bron) s.push({ naam: 'Pand', detail: pand.bron, zekerheid: 'feit' });
    if (brandweer?.length) {
      s.push({
        naam: 'Brandweerkazernes',
        detail: `${brandweer[0].bron} — afstand hemelsbreed=feit, opkomsttijd=schatting`,
        zekerheid: 'schatting'
      });
    }
    if (water?.bron) s.push({ naam: 'Watervoorziening', detail: water.bron, zekerheid: 'schatting' });
    if (extra?.cbs?.bron) s.push({ naam: 'CBS buurt', detail: extra.cbs.bron, zekerheid: 'feit' });
    if (extra?.perceel?.bron) s.push({ naam: 'Kadaster', detail: extra.perceel.bron, zekerheid: 'feit' });
    if (extra?.wegen?.bron) s.push({ naam: 'NWB wegen', detail: extra.wegen.bron + ' (indicatie)', zekerheid: 'schatting' });
    if (extra?.weer?.bron) s.push({ naam: 'Weer/hoogte', detail: extra.weer.bron + ' — LIWO-proxy=schatting', zekerheid: 'schatting' });
    s.push({ naam: 'Checklist', detail: 'RiskWalk-onderwerpen — status pas feit na inspectie/antwoord', zekerheid: 'controleer' });
    return s;
  }

  function writeConclusion({ niveau, score, nearest, riskClass, pand, functie, openstaand, tekortkomingen, feiten, teControleren, cbs, weer }) {
    const harde = [];
    if (pand?.bouwjaar) harde.push(`BAG-bouwjaar ${pand.bouwjaar}, status “${pand.status || '?'}”`);
    if (nearest) harde.push(`dichtstbijzijnde kazerne ${nearest.name} op ${nearest.distance_km} km hemelsbreed`);
    if (cbs?.bevolkingsdichtheid != null) {
      harde.push(`CBS-buurt ${cbs.bevolkingsdichtheid} inw/km², ${cbs.bedrijfsvestigingen ?? '?'} bedrijven`);
    }
    if (weer?.elevation_m != null) harde.push(`Open-Meteo hoogte ${weer.elevation_m} m`);

    const parts = [];
    parts.push(`Inspectiescore ${score}/100 (${niveau}) — dit is géén verzekeringsadvies, alleen openstaande controlepunten.`);
    if (functie) parts.push(`Formulierfunctie “${functie}” — CONTROLEER of dit klopt op locatie.`);
    if (harde.length) parts.push(`Harde feiten: ${harde.join('; ')}.`);
    if (nearest) {
      parts.push(`SCHATTING opkomst ±${nearest.duration_min} min / klasse “${riskClass}” — verifiëren bij veiligheidsregio.`);
    }
    parts.push(`${feiten.length} checklistpunten met harde bron; ${teControleren.length} punten CONTROLEER/SCHATTING (${openstaand.length} nog onbekend).`);
    return parts.join(' ');
  }

  /** Geen verzonnen materiaalkennis — alleen wat de gebruiker expliciet moet controleren */
  function demoFotoHints(functie) {
    return {
      constructie: null,
      gevel: null,
      materialen_gevel: [],
      materialen_dak: [],
      kozijnen: [],
      isolatie: [],
      sandwich: null,
      bouwjaar: null
    };
  }

  return { TOPICS, STANDARD_QUESTIONS, FUNCTIE_VRAGEN, buildReport, demoFotoHints };
})();
