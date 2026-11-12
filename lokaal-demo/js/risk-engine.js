/**
 * Risico-engine voor taxateur / risicodeskundige
 * Gebaseerd op RiskWalk-inspectieonderwerpen + gebruiksfunctie-specifieke vragen
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

  function buildReport({ locatie, pand, brandweer, water, functie, fotoHints, antwoorden, extra }) {
    extra = extra || {};
    const cbs = extra.cbs || null;
    const weer = extra.weer || null;
    const wegen = extra.wegen || null;
    const perceel = extra.perceel || null;

    const bouwjaar = pand?.bouwjaar || fotoHints?.bouwjaar || null;
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

    const wozK = cbs?.gemiddelde_woningwaarde_k;

    return {
      timestamp: new Date().toISOString(),
      locatie,
      pand,
      brandweer: {
        nearest,
        stations: brandweer || [],
        riskClass,
        water
      },
      extra: { cbs, weer, wegen, perceel },
      functie,
      bouwjaar,
      age,
      score,
      niveau,
      topics,
      tekortkomingen,
      openstaand,
      vragen,
      materialen: inferMaterials(pand, fotoHints, bouwjaar),
      taxatie: {
        herbouwwaarde_indicatie: typeof wozK === 'number'
          ? `CBS gem. woningwaarde buurt ± €${(wozK * 1000).toLocaleString('nl-NL')} (indicatief, geen herbouwwaarde)`
          : 'n.n.b. — vraag taxateur/calculatie',
        inventaris: 'n.n.b.',
        bedrijfsschade: 'afhankelijk van omzet / max. uitkeringstermijn',
        premie_drivers: tekortkomingen.slice(0, 6).map(t => t.name),
        blootstelling: {
          bevolkingsdichtheid: cbs?.bevolkingsdichtheid ?? null,
          bedrijfsvestigingen: cbs?.bedrijfsvestigingen ?? null,
          omgevingsadressendichtheid: cbs?.omgevingsadressendichtheid ?? null
        },
        perceel_m2: perceel?.grootte_m2 ?? null
      },
      bronnen: collectSources(locatie, pand, brandweer, water, extra),
      conclusie: writeConclusion({ niveau, score, nearest, riskClass, pand, functie, openstaand, tekortkomingen, cbs, weer })
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
        if (a.activities_main) return topic(t, 'ok', a.activities_main);
        if (functie) return topic(t, 'aandacht', `Opgegeven functie: ${functie}. Verifieer feitelijke activiteiten.`);
        return topic(t, 'onbekend', 'Nog geen activiteiten vastgelegd.');

      case 'gebouwen':
        if (pand) {
          return topic(t, 'ok', `BAG-pand: bouwjaar ${pand.bouwjaar || '?'}, status ${pand.status || '?'}, VBO’s ${pand.aantal_verblijfsobjecten ?? '?'}`);
        }
        return topic(t, 'onbekend', 'Geen pandgegevens uit BAG.');

      case 'constructie':
        if (a.construction) return topic(t, 'ok', a.construction);
        if (fotoHints?.constructie) return topic(t, 'aandacht', fotoHints.constructie + ' (uit foto/schatting)');
        return topic(t, 'onbekend', 'Draagconstructie niet vastgesteld — vraag op of inspecteer.');

      case 'gevel_dak':
        if (a.facade) return topic(t, 'ok', a.facade);
        if (fotoHints?.gevel) return topic(t, 'aandacht', fotoHints.gevel);
        return topic(t, 'aandacht', 'Controleer brandklasse gevel/dakisolatie (PIR/PUR vs minerale wol).');

      case 'compartimentering':
        if (a.compartment) return topic(t, a.compartment.toLowerCase().includes('geen') ? 'tekort' : 'ok', a.compartment);
        return topic(t, 'onbekend', 'WBDBO / branddeuren / doorvoeringen niet zichtbaar — kritiek inspectiepunt.');

      case 'elektra':
        if (a.electrical) return topic(t, 'ok', a.electrical);
        if (age != null && age > 30) return topic(t, 'aandacht', `Bouwjaar ±${bouwjaar}: vraag recente elektra-keuring (NEN 3140 / Scope).`);
        return topic(t, 'onbekend', 'Geen keuringsinformatie bekend.');

      case 'verwarming':
        if (a.heating) return topic(t, 'ok', a.heating);
        if (typeof C.perc_aardgaswoningen === 'number' && C.perc_aardgaswoningen >= 70) {
          return topic(t, 'aandacht', `CBS: ${C.perc_aardgaswoningen}% aardgaswoningen (gem. ${C.gem_aardgasverbruik ?? '?'} m³). Verifieer CV/gas op object.`);
        }
        return topic(t, 'onbekend', 'Type CV/stookruimte/gas onbekend.');

      case 'detectie':
        if (a.detection) {
          const low = /geen|nee/i.test(a.detection);
          return topic(t, low ? 'tekort' : 'ok', a.detection);
        }
        if (/hotel|zorg|opslag/i.test(functie || '')) return topic(t, 'aandacht', 'Functie vraagt om adequate detectie — status onbekend.');
        return topic(t, 'onbekend', 'Detectie/doormelding niet vastgesteld.');

      case 'blusmiddelen':
        if (a.extinguishers) return topic(t, /geen|nee/i.test(a.extinguishers) ? 'tekort' : 'ok', a.extinguishers);
        return topic(t, 'onbekend', 'Handblussers/haspels/sprinkler niet bevestigd.');

      case 'huishouding':
        if (a.housekeeping) return topic(t, /slecht|rommel/i.test(a.housekeeping) ? 'aandacht' : 'ok', a.housekeeping);
        return topic(t, 'onbekend', 'Orde & netheid tijdens inspectie beoordelen.');

      case 'roken':
        return topic(t, 'onbekend', 'Rookbeleid / open vuur / hot work permit controleren.');

      case 'accus':
        if (a.accus) return topic(t, /ja|lithium|laden/i.test(a.accus) ? 'aandacht' : 'ok', a.accus);
        if (/garage|opslag|industrie/i.test(functie || '')) return topic(t, 'aandacht', 'Functie: vraag expliciet naar lithium-laden / EV.');
        return topic(t, 'onbekend', "Lithium-ion laden: vrije ruimte ≥2 m, detectie, niet onbeheerd laden.");

      case 'gevaarlijk':
        if (a.hazmat) return topic(t, /ja|aanwezig/i.test(a.hazmat) ? 'aandacht' : 'ok', a.hazmat);
        if (/industrie|metaal|garage|opslag/i.test(functie || '')) return topic(t, 'aandacht', 'Functie suggereert mogelijke gevaarlijke stoffen.');
        return topic(t, 'onbekend', 'ADR/stoffenlijst opvragen.');

      case 'machines':
        if (/industrie|metaal|hout|garage/i.test(functie || '')) return topic(t, 'aandacht', 'Procesgebonden brandrisico’s inventariseren.');
        return topic(t, 'ok', 'Geen zware processen verwacht op basis van functie — verifieer.');

      case 'opslag':
        if (/opslag|winkel|industrie/i.test(functie || '')) return topic(t, 'aandacht', 'Opslaghoogte, brandlast en sprinklercompatibiliteit checken.');
        return topic(t, 'onbekend', 'Interne opslag beoordelen.');

      case 'buitenopslag':
        return topic(t, 'onbekend', 'Afstand tot gevel, containers, pallets, gasflessen buiten controleren.');

      case 'inbraak':
        if (a.security) return topic(t, 'ok', a.security);
        return topic(t, 'aandacht', 'Taxatie: slotenklasse, alarm, camera, bereikbaarheid — premie-relevant.');

      case 'water':
        if (a.water_storm) return topic(t, /lekkage|overlast|accumulatie/i.test(a.water_storm) ? 'aandacht' : 'ok', a.water_storm);
        if (W.elevation_m != null || W.max_neerslag_7d_mm != null) {
          const notes = [];
          if (W.elevation_m != null) notes.push(`hoogte ±${W.elevation_m} m (proxy ${W.overstroming_hoogte_proxy})`);
          if (W.max_neerslag_7d_mm != null) notes.push(`max neerslag 7d ${W.max_neerslag_7d_mm} mm (${W.water_neerslag_indicatie})`);
          let status = 'ok';
          if (W.overstroming_hoogte_proxy === 'hoog' || W.water_neerslag_indicatie === 'hoog') status = 'aandacht';
          else if (W.overstroming_hoogte_proxy === 'middel' || W.water_neerslag_indicatie === 'middel') status = 'aandacht';
          return topic(t, status, 'Open-Meteo: ' + notes.join('; ') + '. Geen officiële LIWO — check kelder/dak.');
        }
        return topic(t, 'onbekend', 'Dakafvoer, kelder, leidingbreukscenario’s.');

      case 'storm':
        if (W.max_windstoten_7d_kmh != null) {
          const st = W.storm_indicatie || 'laag';
          const status = st === 'hoog' ? 'tekort' : st === 'middel' ? 'aandacht' : 'ok';
          return topic(t, status, `Open-Meteo: max windstoten 7d ${W.max_windstoten_7d_kmh} km/h (${st}). Check dak/gevel.`);
        }
        return topic(t, 'onbekend', 'Dakverankering, gevelplaten, luifels, bomen nabij.');

      case 'bedrijfsschade':
        if (a.bi) return topic(t, 'ok', a.bi);
        return topic(t, 'aandacht', 'Vraag omzetafhankelijkheid, uitwijkmogelijkheid, max. schadeperiode.');

      case 'brandweer': {
        const parts = [];
        if (nearest) parts.push(`Opkomst ±${nearest.duration_min} min / ${nearest.distance_km} km (${nearest.name}).`);
        if (C.afstand_brandweer_km != null) parts.push(`CBS gem. afstand brandweer ${C.afstand_brandweer_km} km.`);
        if (R.bereikbaarheid_indicatie) parts.push(`NWB: ${R.bereikbaarheid_indicatie}`);
        if (!parts.length) return topic(t, 'onbekend', 'Geen kazerne/CBS — veiligheidsregio handmatig checken.');
        const note = parts.join(' ');
        if (riskClass === 'Hoog') return topic(t, 'tekort', note);
        if (riskClass === 'Gemiddeld' || /Beperkt/.test(R.bereikbaarheid_indicatie || '')) return topic(t, 'aandacht', note);
        return topic(t, 'ok', note);
      }

      case 'ontruiming':
        if (/hotel|zorg|onderwijs/i.test(functie || '')) return topic(t, 'aandacht', 'Kwetsbare populatie: ontruimingsplan + oefeningen vereist.');
        return topic(t, 'onbekend', 'BHV-organisatie en ontruimingsplattegronden controleren.');

      case 'dakveiligheid':
        if (a.solar) return topic(t, /ja|paneel/i.test(a.solar) ? 'aandacht' : 'ok', a.solar);
        return topic(t, 'onbekend', 'PV-installatie, ballast, doorvoeren, blusprocedure.');

      case 'sandwich':
        if (fotoHints?.sandwich) return topic(t, 'aandacht', fotoHints.sandwich);
        if (/industrie|opslag/i.test(functie || '')) return topic(t, 'aandacht', 'Industrieel: vraag kernisolatie sandwichpanelen (PIR/PUR/MW).');
        return topic(t, 'onbekend', 'Isolatiebrandgedrag niet vastgesteld.');

      default:
        return topic(t, 'onbekend', '');
    }
  }

  function topic(t, status, note) {
    return { id: t.id, name: t.name, group: t.group, status, note };
  }

  function buildQuestions(functie, topics) {
    const qs = [...STANDARD_QUESTIONS];
    const extra = FUNCTIE_VRAGEN[functie] || [];
    extra.forEach(e => qs.push({ id: e.id, text: e.text, waarom: e.waarom }));

    // Prioritize unknowns
    const unknownIds = new Set(topics.filter(t => t.status === 'onbekend' || t.status === 'aandacht').map(t => t.id));
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
    const gevel = fotoHints?.materialen_gevel || ['Nader te bepalen (foto/inspectie)'];
    const dak = fotoHints?.materialen_dak || ['Nader te bepalen'];
    const isolatie = [];
    if (bouwjaar) {
      if (bouwjaar >= 1992) isolatie.push('Spouw-/dakisolatie waarschijnlijk (bouwbesluit-tijdperk)');
      else if (bouwjaar >= 1975) isolatie.push('Mogelijk nageïsoleerd — verifiëren');
      else isolatie.push('Oudere bouw: isolatie vaak beperkt of later aangebracht');
    }
    if (fotoHints?.isolatie) isolatie.push(...fotoHints.isolatie);
    return {
      gevel,
      dak,
      kozijnen: fotoHints?.kozijnen || ['Nader te bepalen'],
      isolatie,
      gebruiksdoel_bag: pand?.gebruiksdoel || []
    };
  }

  function collectSources(locatie, pand, brandweer, water, extra) {
    const s = [];
    if (locatie?.bron) s.push({ naam: 'Adres', detail: locatie.bron });
    if (pand?.bron) s.push({ naam: 'Pand', detail: pand.bron });
    if (brandweer?.length) s.push({ naam: 'Brandweerkazernes', detail: brandweer[0].bron });
    if (water?.bron) s.push({ naam: 'Watervoorziening', detail: water.bron });
    if (extra?.cbs?.bron) s.push({ naam: 'CBS buurt', detail: extra.cbs.bron });
    if (extra?.perceel?.bron) s.push({ naam: 'Kadaster', detail: extra.perceel.bron });
    if (extra?.wegen?.bron) s.push({ naam: 'NWB wegen', detail: extra.wegen.bron });
    if (extra?.weer?.bron) s.push({ naam: 'Weer/hoogte', detail: extra.weer.bron });
    s.push({ naam: 'Checklist', detail: 'RiskWalk / risicodeskundige praktijk' });
    return s;
  }

  function writeConclusion({ niveau, score, nearest, riskClass, pand, functie, openstaand, tekortkomingen, cbs, weer }) {
    const parts = [];
    parts.push(`Risiconiveau ${niveau.toUpperCase()} (score ${score}/100) voor functie “${functie || 'onbekend'}”.`);
    if (pand?.bouwjaar) parts.push(`BAG-bouwjaar ${pand.bouwjaar}, status “${pand.status || '?'}”.`);
    if (nearest) parts.push(`Dichtstbijzijnde kazerne: ${nearest.name} (±${nearest.duration_min} min, opkomstklasse ${riskClass}).`);
    if (cbs?.bevolkingsdichtheid) parts.push(`CBS blootstelling: ${cbs.bevolkingsdichtheid} inw/km², ${cbs.bedrijfsvestigingen ?? '?'} bedrijven.`);
    if (weer?.elevation_m != null) parts.push(`Hoogte ±${weer.elevation_m} m (overstromingsproxy ${weer.overstroming_hoogte_proxy}).`);
    parts.push(`${tekortkomingen.length} aandacht-/tekortpunten, ${openstaand.length} onderwerpen nog onbekend — deze bepalen de inspectieagenda.`);
    return parts.join(' ');
  }

  /** Eenvoudige foto-hints zonder AI (bestandsnaam / gebruiker kan later GPT koppelen) */
  function demoFotoHints(functie) {
    return {
      constructie: 'Vermoedelijk traditioneel metselwerk of beton (niet geverifieerd)',
      gevel: 'Gevelmateriaal uit foto niet hard vastgesteld — controleer brandklasse',
      materialen_gevel: ['Nader te inspecteren'],
      materialen_dak: ['Nader te inspecteren'],
      kozijnen: ['Nader te inspecteren'],
      isolatie: [],
      sandwich: /industrie|opslag/i.test(functie || '') ? 'Let op sandwichpanelen bij hallen' : null
    };
  }

  return { TOPICS, STANDARD_QUESTIONS, FUNCTIE_VRAGEN, buildReport, demoFotoHints };
})();
