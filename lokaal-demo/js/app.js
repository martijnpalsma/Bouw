(() => {
  const uploadZone = document.getElementById('uploadZone');
  const fileInput = document.getElementById('fileInput');
  const analyzeBtn = document.getElementById('analyzeBtn');
  const exportBtn = document.getElementById('exportBtn');
  const loading = document.getElementById('loading');
  const loadingText = document.getElementById('loadingText');
  const results = document.getElementById('results');
  const placeholder = document.getElementById('placeholder');

  let selectedFile = null;
  let previewUrl = null;
  let lastReport = null;

  uploadZone.addEventListener('click', () => fileInput.click());
  uploadZone.addEventListener('dragover', e => { e.preventDefault(); uploadZone.classList.add('dragover'); });
  uploadZone.addEventListener('dragleave', () => uploadZone.classList.remove('dragover'));
  uploadZone.addEventListener('drop', e => {
    e.preventDefault();
    uploadZone.classList.remove('dragover');
    if (e.dataTransfer.files[0]) handleFile(e.dataTransfer.files[0]);
  });
  fileInput.addEventListener('change', e => { if (e.target.files[0]) handleFile(e.target.files[0]); });

  function handleFile(file) {
    if (!file.type.startsWith('image/')) return alert('Kies een afbeelding');
    selectedFile = file;
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    previewUrl = URL.createObjectURL(file);
    uploadZone.innerHTML = `<img src="${previewUrl}" alt="Preview">`;
  }

  analyzeBtn.addEventListener('click', () => runFullAnalysis());
  exportBtn.addEventListener('click', () => {
    if (!lastReport) return;
    const blob = new Blob([JSON.stringify(lastReport, null, 2)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `risicoscan_${(lastReport.locatie?.postcode || 'object').replace(/\s/g,'')}.json`;
    a.click();
  });

  async function runFullAnalysis(extraAnswers = {}) {
    const postcode = document.getElementById('postcode').value.trim();
    const huisnummer = document.getElementById('huisnummer').value.trim();
    const functie = document.getElementById('functie').value;
    if (!postcode) return alert('Vul een postcode in');

    placeholder.style.display = 'none';
    results.classList.remove('show');
    loading.classList.add('show');
    analyzeBtn.disabled = true;

    try {
      loadingText.textContent = 'Zoekt adres in BAG/PDOK…';
      const locatie = await OpenData.zoekAdres(postcode, huisnummer);

      loadingText.textContent = 'Haalt pandkenmerken (bouwjaar, gebruiksdoel)…';
      let pand = null;
      if (locatie.lat != null) {
        try { pand = await OpenData.haalPand(locatie.lat, locatie.lon); }
        catch (e) { console.warn(e); }
      }

      loadingText.textContent = 'Zoekt brandweerkazernes via OpenStreetMap…';
      let brandweer = [];
      if (locatie.lat != null) {
        try { brandweer = await OpenData.zoekBrandweer(locatie.lat, locatie.lon); }
        catch (e) { console.warn(e); }
      }

      loadingText.textContent = 'Haalt CBS, kadaster, wegen en weer…';
      let extra = {};
      if (locatie.lat != null) {
        try { extra = await ExtraApis.verzamel(locatie.lat, locatie.lon); }
        catch (e) { console.warn(e); }
      }

      const oad = extra.cbs?.omgevingsadressendichtheid;
      const stedelijk = typeof oad === 'number' ? oad >= 1500 : true;
      const water = OpenData.schatWatervoorziening(stedelijk);
      const fotoHints = RiskEngine.demoFotoHints(functie);
      if (selectedFile) {
        fotoHints.gevel = 'Foto geüpload — visuele AI-analyse optioneel via Flask; checklist hieronder is leidend.';
      }

      loadingText.textContent = 'Bouwt risicodeskundige rapportage…';
      const report = RiskEngine.buildReport({
        locatie, pand, brandweer, water, functie, fotoHints, antwoorden: extraAnswers, extra
      });
      lastReport = report;
      renderReport(report);
      exportBtn.disabled = false;
    } catch (err) {
      results.innerHTML = `<div class="section open"><div class="section-body" style="display:block;color:#6b1f1f">
        <strong>Fout:</strong> ${escapeHtml(err.message || String(err))}
      </div></div>`;
      results.classList.add('show');
    } finally {
      loading.classList.remove('show');
      analyzeBtn.disabled = false;
    }
  }

  const statusLabel = { ok: 'In orde', aandacht: 'Aandacht', tekort: 'Tekort', onbekend: 'Onbekend' };
  const statusIcon = { ok: '✅', aandacht: '⚠️', tekort: '❌', onbekend: '❔' };
  const GROUP_ORDER = ['Algemeen', 'Bouwkundig', 'Installaties', 'Brand', 'Speciaal risico', 'Organisatie', 'Security', 'Elementair', 'Taxatie'];
  const GROUP_HINTS = {
    Algemeen: 'Vastleggen wat er feitelijk gebeurt en welke objecten er zijn.',
    Bouwkundig: 'Constructie, gevel, dak, isolatiebrandgedrag en PV.',
    Installaties: 'Elektra- en verwarmingsrisico’s — vaak oorzaak van brand.',
    Brand: 'Detectie, blusmiddelen, compartimentering en repressie.',
    'Speciaal risico': 'Proces-, opslag- en lithiumrisico’s die premie sterk beïnvloeden.',
    Organisatie: 'Mens & organisatie: BHV, orde, rookbeleid.',
    Security: 'Inbraak/diefstal — relevant voor taxatie en waarborg.',
    Elementair: 'Water- en stormschade (Open-Meteo + inspectie).',
    Taxatie: 'Bedrijfsschade, waarden en continuïteit.'
  };

  function renderReport(r) {
    lastReport = r;
    const L = r.locatie || {};
    const groups = {};
    (r.topics || []).forEach(t => {
      groups[t.group] = groups[t.group] || [];
      groups[t.group].push(t);
    });
    const groupNames = GROUP_ORDER.filter(g => groups[g]);
    Object.keys(groups).forEach(g => { if (!groupNames.includes(g)) groupNames.push(g); });

    const counts = {
      tekort: (r.tekortkomingen || []).filter(t => t.status === 'tekort').length,
      aandacht: (r.tekortkomingen || []).filter(t => t.status === 'aandacht').length,
      onbekend: (r.openstaand || []).length
    };

    results.innerHTML = `
      <div class="risk-banner ${r.niveau}">
        <div>
          <div style="opacity:.85;font-size:.78rem;text-transform:uppercase;letter-spacing:.06em">Risiconiveau</div>
          <strong>${r.niveau.toUpperCase()}</strong>
          <div style="opacity:.9;font-size:.85rem;margin-top:.25rem">${escapeHtml(L.weergavenaam || '')} · ${escapeHtml(r.functie || '')}</div>
        </div>
        <div class="score">${r.score}</div>
      </div>

      <nav class="tabs-bar" id="mainTabs" role="tablist">
        ${tabBtn('overzicht', 'Overzicht', true)}
        ${tabBtn('object', 'Object')}
        ${tabBtn('omgeving', 'Omgeving')}
        ${tabBtn('brandweer', 'Brandweer')}
        ${tabBtn('checklist', 'Checklist', false, (r.topics || []).length)}
        ${tabBtn('taxatie', 'Taxatie')}
        ${tabBtn('vragen', 'Vragen', false, (r.vragen || []).length)}
      </nav>

      <div class="tab-panel active" data-tab="overzicht">${panelOverzicht(r, counts)}</div>
      <div class="tab-panel" data-tab="object">${panelObject(r)}</div>
      <div class="tab-panel" data-tab="omgeving">${panelOmgeving(r)}</div>
      <div class="tab-panel" data-tab="brandweer">${panelBrandweer(r)}</div>
      <div class="tab-panel" data-tab="checklist">${panelChecklist(r, groups, groupNames)}</div>
      <div class="tab-panel" data-tab="taxatie">${panelTaxatie(r)}</div>
      <div class="tab-panel" data-tab="vragen">${panelVragen(r)}</div>

      <p class="footer-meta">Gegenereerd ${escapeHtml(r.timestamp || '')} · lokaal · BAG/PDOK · CBS · Kadaster · NWB · OSM · Open-Meteo</p>
    `;

    results.classList.add('show');
    wireTabs(results);
    wireChecklist(results, r);
    wireVragen();
  }

  function tabBtn(id, label, active = false, count) {
    return `<button type="button" class="tab-btn ${active ? 'active' : ''}" data-tab="${id}" role="tab">
      ${label}${count != null ? `<span class="count">${count}</span>` : ''}
    </button>`;
  }

  function activateTab(root, tabId) {
    root.querySelectorAll('#mainTabs .tab-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.tab === tabId);
    });
    root.querySelectorAll(':scope > .tab-panel').forEach(p => {
      p.classList.toggle('active', p.dataset.tab === tabId);
    });
  }

  function wireTabs(root) {
    root.querySelectorAll('#mainTabs .tab-btn').forEach(btn => {
      btn.addEventListener('click', () => activateTab(root, btn.dataset.tab));
    });
    root.querySelectorAll('[data-goto]').forEach(btn => {
      btn.addEventListener('click', () => activateTab(root, btn.dataset.goto));
    });
  }

  function panelOverzicht(r, counts) {
    const tekort = (r.tekortkomingen || []).filter(t => t.status === 'tekort');
    const aandacht = (r.tekortkomingen || []).filter(t => t.status === 'aandacht');
    return `
      <div class="stat-row">
        <div class="stat-card"><div class="label">Score</div><div class="value">${r.score}</div></div>
        <div class="stat-card"><div class="label">Tekort</div><div class="value">${counts.tekort}</div></div>
        <div class="stat-card"><div class="label">Aandacht</div><div class="value">${counts.aandacht}</div></div>
        <div class="stat-card"><div class="label">Onbekend</div><div class="value">${counts.onbekend}</div></div>
      </div>
      <p style="font-size:.92rem;margin-bottom:1rem">${escapeHtml(r.conclusie || '')}</p>
      <h3 style="font-size:.85rem;margin-bottom:.5rem;color:var(--steel)">Inspectieagenda</h3>
      <ul class="summary-list">
        ${[...tekort, ...aandacht].slice(0, 10).map(t => `
          <li><span>${statusIcon[t.status]}</span><div><strong>${escapeHtml(t.name)}</strong><br><span class="muted">${escapeHtml(t.note || '')}</span></div></li>
        `).join('') || '<li><span>❔</span><div>Nog geen aandachtspunten — bekijk Checklist.</div></li>'}
      </ul>
      <div class="btn-row" style="margin-top:1rem">
        <button type="button" class="btn-secondary" data-goto="checklist">Open checklist</button>
        <button type="button" class="btn-secondary" data-goto="vragen">Beantwoord vragen</button>
      </div>`;
  }

  function panelObject(r) {
    const L = r.locatie || {};
    const P = r.pand || {};
    const perc = r.extra?.perceel;
    return `
      <h3 style="font-size:.9rem;margin-bottom:.75rem;color:var(--steel)">📍 Locatie & BAG</h3>
      <dl class="kv">
        <dt>Adres</dt><dd>${escapeHtml(L.weergavenaam || '—')}</dd>
        <dt>Buurt / wijk</dt><dd>${escapeHtml([L.buurt, L.wijk].filter(Boolean).join(' · ') || '—')}</dd>
        <dt>Gemeente</dt><dd>${escapeHtml([L.gemeente, L.provincie].filter(Boolean).join(', ') || '—')}</dd>
        <dt>Waterschap</dt><dd>${escapeHtml(L.waterschap || '—')}</dd>
        <dt>Coördinaten</dt><dd>${L.lat != null ? `${L.lat.toFixed(5)}, ${L.lon.toFixed(5)}` : '—'}</dd>
        <dt>Bron</dt><dd><span class="chip source">${escapeHtml(L.bron || '')}</span></dd>
      </dl>
      ${P.bouwjaar ? `
      <h3 style="font-size:.9rem;margin:1rem 0 .5rem;color:var(--steel)">Pand (BAG WFS)</h3>
      <dl class="kv">
        <dt>Bouwjaar</dt><dd>${P.bouwjaar}${r.age != null ? ` (±${r.age} jaar)` : ''}</dd>
        <dt>Status</dt><dd>${escapeHtml(P.status || '—')}</dd>
        <dt>Oppervlakte</dt><dd>${P.oppervlakte_min ?? '?'} – ${P.oppervlakte_max ?? '?'} m²</dd>
        <dt>VBO’s</dt><dd>${P.aantal_verblijfsobjecten ?? '—'}</dd>
        <dt>Gebruiksdoel</dt><dd>${escapeHtml((P.gebruiksdoel || []).join(', ') || '—')}</dd>
      </dl>` : '<p class="muted">Geen pand in BAG WFS.</p>'}
      ${perc ? `<h3 style="font-size:.9rem;margin:1rem 0 .5rem;color:var(--steel)">Kadaster</h3>
      <dl class="kv">
        <dt>Perceel</dt><dd>${escapeHtml([perc.kadastrale_gemeente, perc.sectie, perc.perceelnummer].filter(Boolean).join(' '))} · ${perc.grootte_m2 ?? '?'} m²</dd>
      </dl>` : ''}
      <h3 style="font-size:.9rem;margin:1rem 0 .5rem;color:var(--steel)">🏗️ Materialen & isolatie</h3>
      <div class="chips">
        ${(r.materialen?.gevel || []).map(m => `<span class="chip">${escapeHtml(m)}</span>`).join('')}
        ${(r.materialen?.dak || []).map(m => `<span class="chip">${escapeHtml(m)}</span>`).join('')}
        ${(r.materialen?.kozijnen || []).map(m => `<span class="chip">${escapeHtml(m)}</span>`).join('')}
      </div>
      <div class="chips">
        ${(r.materialen?.isolatie || []).map(m => `<span class="chip ok">${escapeHtml(m)}</span>`).join('')}
        ${(r.materialen?.gebruiksdoel_bag || []).map(m => `<span class="chip source">${escapeHtml(m)}</span>`).join('')}
      </div>`;
  }

  function panelOmgeving(r) {
    const c = r.extra?.cbs;
    const w = r.extra?.weer;
    const wegen = r.extra?.wegen;
    return `
      ${c ? `
      <h3 style="font-size:.9rem;margin-bottom:.5rem;color:var(--steel)">📊 CBS buurt</h3>
      <div class="stat-row">
        <div class="stat-card"><div class="label">Dichtheid</div><div class="value small">${c.bevolkingsdichtheid ?? '—'} /km²</div></div>
        <div class="stat-card"><div class="label">Bedrijven</div><div class="value">${c.bedrijfsvestigingen ?? '—'}</div></div>
        <div class="stat-card"><div class="label">WOZ ±</div><div class="value small">${c.gemiddelde_woningwaarde_k != null ? '€' + (c.gemiddelde_woningwaarde_k * 1000).toLocaleString('nl-NL') : '—'}</div></div>
        <div class="stat-card"><div class="label">Gas</div><div class="value small">${c.perc_aardgaswoningen ?? '—'}%</div></div>
      </div>
      <dl class="kv">
        <dt>Buurt</dt><dd>${escapeHtml(c.buurtnaam || '—')} (${escapeHtml(c.buurtcode || '')})</dd>
        <dt>OAD</dt><dd>${c.omgevingsadressendichtheid ?? '—'} · stedelijkheid ${c.stedelijkheid ?? '—'}</dd>
        <dt>Afstanden</dt><dd>Brandweer ${c.afstand_brandweer_km ?? '—'} km · Ziekenhuis ${c.afstand_ziekenhuis_km ?? '—'} km · Oprit ${c.afstand_oprit_km ?? '—'} km</dd>
        <dt>Bron</dt><dd><span class="chip source">${escapeHtml(c.bron || '')}</span></dd>
      </dl>` : '<p class="muted">Geen CBS-data.</p>'}
      ${wegen ? `
      <h3 style="font-size:.9rem;margin:1rem 0 .5rem;color:var(--steel)">🗺️ Bereikbaarheid (NWB)</h3>
      <dl class="kv">
        <dt>Indicatie</dt><dd>${escapeHtml(wegen.bereikbaarheid_indicatie || '')}</dd>
        <dt>Straten</dt><dd>${escapeHtml((wegen.straten || []).join(', ') || '—')}</dd>
      </dl>` : ''}
      ${w ? `
      <h3 style="font-size:.9rem;margin:1rem 0 .5rem;color:var(--steel)">🌧️ Weer & hoogte</h3>
      <dl class="kv">
        <dt>Hoogte</dt><dd>${w.elevation_m ?? '—'} m · proxy <strong>${escapeHtml(w.overstroming_hoogte_proxy || '')}</strong></dd>
        <dt>Neerslag 7d</dt><dd>max ${w.max_neerslag_7d_mm ?? '—'} mm (${escapeHtml(w.water_neerslag_indicatie || '')})</dd>
        <dt>Wind 7d</dt><dd>stoten ${w.max_windstoten_7d_kmh ?? '—'} km/h (${escapeHtml(w.storm_indicatie || '')})</dd>
      </dl>
      <div class="chips">${(w.dagen || []).slice(0, 7).map(d =>
        `<span class="chip">${escapeHtml((d.datum || '').slice(5))}: ${d.neerslag_mm ?? 0}mm / ${d.stoten_kmh ?? '—'}km/h</span>`
      ).join('')}</div>
      <p class="muted" style="margin-top:.5rem">${escapeHtml(w.toelichting || '')}</p>` : ''}`;
  }

  function panelBrandweer(r) {
    const B = r.brandweer || {};
    const nearest = B.nearest;
    const water = B.water || {};
    return `
      ${nearest ? `
      <div class="stat-row">
        <div class="stat-card"><div class="label">Afstand</div><div class="value small">${nearest.distance_km} km</div></div>
        <div class="stat-card"><div class="label">Opkomst</div><div class="value small">±${nearest.duration_min} min</div></div>
        <div class="stat-card"><div class="label">Klasse</div><div class="value small">${escapeHtml(B.riskClass || '')}</div></div>
      </div>
      <dl class="kv">
        <dt>Kazerne</dt><dd>${escapeHtml(nearest.name)} (${escapeHtml(nearest.type)})</dd>
        <dt>Adres</dt><dd>${escapeHtml(nearest.address || '')}</dd>
        <dt>Bron</dt><dd><span class="chip source">${escapeHtml(nearest.bron || '')}</span></dd>
      </dl>
      <h3 style="font-size:.85rem;margin:1rem 0 .4rem">Andere kazernes</h3>
      ${(B.stations || []).slice(1, 6).map(s =>
        `<div style="padding:.35rem 0;border-bottom:1px solid var(--line);font-size:.88rem">${escapeHtml(s.name)} · ${s.distance_km} km · ±${s.duration_min} min</div>`
      ).join('')}` : '<p>Geen kazerne gevonden.</p>'}
      <h3 style="font-size:.9rem;margin:1rem 0 .4rem;color:var(--steel)">💧 Watervoorziening</h3>
      ${(water.items || []).map(w => `
        <div style="padding:.45rem 0;border-bottom:1px solid var(--line);font-size:.86rem">
          <strong>${escapeHtml(w.type)}</strong> — ${escapeHtml(w.location)} · ${escapeHtml(w.distance)} · ${escapeHtml(w.capacity)}<br>
          <span class="muted">Toegang: ${escapeHtml(w.accessibility)} · ${escapeHtml(w.zekerheid || '')}</span>
        </div>`).join('')}
      <div class="chips" style="margin-top:.6rem">${(water.aandacht || []).map(a => `<span class="chip warn">${escapeHtml(a)}</span>`).join('')}</div>
      <p class="muted" style="margin-top:.5rem">${escapeHtml(water.bron || '')}</p>`;
  }

  function panelChecklist(r, groups, groupNames) {
    const first = groupNames[0] || 'Algemeen';
    return `
      <p class="muted" style="margin-bottom:.75rem">Zet status tijdens inspectie. Notities blijven in dit rapport (lokaal).</p>
      <div class="subtabs" id="checklistSubtabs">
        ${groupNames.map((g, i) => {
          const n = (groups[g] || []).filter(t => t.status !== 'ok').length;
          return `<button type="button" class="subtab-btn ${i === 0 ? 'active' : ''}" data-group="${escapeHtml(g)}">${escapeHtml(g)}${n ? ` (${n})` : ''}</button>`;
        }).join('')}
      </div>
      ${groupNames.map((g, i) => `
        <div class="subpanel ${i === 0 ? 'active' : ''}" data-group-panel="${escapeHtml(g)}" style="display:${i === 0 ? 'block' : 'none'}">
          <p class="muted" style="margin-bottom:.75rem">${escapeHtml(GROUP_HINTS[g] || '')}</p>
          ${(groups[g] || []).map(t => topicCard(t)).join('')}
        </div>
      `).join('')}`;
  }

  function topicCard(t) {
    return `
      <article class="topic-card" data-topic-id="${escapeHtml(t.id)}">
        <header>
          <h4>${statusIcon[t.status] || '❔'} ${escapeHtml(t.name)}</h4>
          <span class="status ${t.status}">${statusLabel[t.status] || t.status}</span>
        </header>
        <p class="muted" data-note-view>${escapeHtml(t.note || '')}</p>
        <div class="topic-actions">
          ${['ok', 'aandacht', 'tekort', 'onbekend'].map(s =>
            `<button type="button" class="status-set ${t.status === s ? 'on-' + s : ''}" data-status="${s}">${statusLabel[s]}</button>`
          ).join('')}
        </div>
        <textarea class="topic-note" placeholder="Inspectienotitie…">${escapeHtml(t.note || '')}</textarea>
      </article>`;
  }

  function panelTaxatie(r) {
    return `
      <dl class="kv">
        <dt>Herbouw</dt><dd>${escapeHtml(r.taxatie?.herbouwwaarde_indicatie || '')}</dd>
        <dt>Inventaris</dt><dd>${escapeHtml(r.taxatie?.inventaris || '')}</dd>
        <dt>Bedrijfsschade</dt><dd>${escapeHtml(r.taxatie?.bedrijfsschade || '')}</dd>
        <dt>Perceel</dt><dd>${r.taxatie?.perceel_m2 != null ? `${r.taxatie.perceel_m2} m²` : '—'}</dd>
        <dt>Blootstelling</dt><dd>${escapeHtml([
          r.taxatie?.blootstelling?.bevolkingsdichtheid != null ? `${r.taxatie.blootstelling.bevolkingsdichtheid} inw/km²` : null,
          r.taxatie?.blootstelling?.bedrijfsvestigingen != null ? `${r.taxatie.blootstelling.bedrijfsvestigingen} bedrijven` : null,
          r.taxatie?.blootstelling?.omgevingsadressendichtheid != null ? `OAD ${r.taxatie.blootstelling.omgevingsadressendichtheid}` : null
        ].filter(Boolean).join(' · ') || '—')}</dd>
      </dl>
      <h3 style="font-size:.85rem;margin:1rem 0 .5rem;color:var(--steel)">Premie-drivers</h3>
      <div class="chips">${(r.taxatie?.premie_drivers || []).map(p => `<span class="chip warn">${escapeHtml(p)}</span>`).join('') || '<span class="muted">Geen</span>'}</div>
      <p style="margin-top:1rem;font-size:.9rem">${escapeHtml(r.conclusie || '')}</p>`;
  }

  function panelVragen(r) {
    return `
      <div class="questions" style="margin:0">
        <h3>❓ Inspectievragen</h3>
        ${(r.vragen || []).map(q => `
          <div class="q-item">
            ${q.prioriteit === 'hoog' ? '<span class="prio">PRIORITEIT</span>' : ''}
            <strong>${escapeHtml(q.vraag)}</strong>
            <small>${escapeHtml(q.reden)}</small>
          </div>`).join('')}
        <div class="answer-grid" id="answerGrid">
          ${(r.vragen || []).map(q => `
            <label>${escapeHtml(q.vraag)}
              <input data-qid="${escapeHtml(q.id)}" placeholder="Jouw antwoord…">
            </label>`).join('')}
        </div>
        <div class="btn-row">
          <button class="btn-ember" id="refineBtn" type="button">Verfijn met antwoorden</button>
        </div>
      </div>`;
  }

  function wireChecklist(root, r) {
    root.querySelectorAll('#checklistSubtabs .subtab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        root.querySelectorAll('#checklistSubtabs .subtab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const g = btn.dataset.group;
        root.querySelectorAll('[data-group-panel]').forEach(p => {
          p.style.display = p.getAttribute('data-group-panel') === g ? 'block' : 'none';
        });
      });
    });

    root.querySelectorAll('.topic-card').forEach(card => {
      const id = card.dataset.topicId;
      card.querySelectorAll('.status-set').forEach(btn => {
        btn.addEventListener('click', () => {
          const status = btn.dataset.status;
          const topic = (r.topics || []).find(t => t.id === id);
          if (topic) topic.status = status;
          card.querySelectorAll('.status-set').forEach(b => {
            b.className = 'status-set' + (b.dataset.status === status ? ` on-${status}` : '');
          });
          const badge = card.querySelector('.status');
          if (badge) {
            badge.className = `status ${status}`;
            badge.textContent = statusLabel[status];
          }
          const iconH = card.querySelector('h4');
          if (iconH) iconH.innerHTML = `${statusIcon[status] || '❔'} ${escapeHtml(topic?.name || '')}`;
          // refresh derived lists
          r.tekortkomingen = (r.topics || []).filter(t => t.status === 'tekort' || t.status === 'aandacht');
          r.openstaand = (r.topics || []).filter(t => t.status === 'onbekend');
        });
      });
      const ta = card.querySelector('.topic-note');
      ta?.addEventListener('change', () => {
        const topic = (r.topics || []).find(t => t.id === id);
        if (topic) topic.note = ta.value;
        const view = card.querySelector('[data-note-view]');
        if (view) view.textContent = ta.value;
      });
    });
  }

  function wireVragen() {
    document.getElementById('refineBtn')?.addEventListener('click', () => {
      const antwoorden = {};
      document.querySelectorAll('#answerGrid input').forEach(inp => {
        if (inp.value.trim()) antwoorden[inp.dataset.qid] = inp.value.trim();
      });
      if (!Object.keys(antwoorden).length) return alert('Vul eerst één of meer antwoorden in.');
      runFullAnalysis(antwoorden);
    });
  }

  function escapeHtml(s) {
    return String(s ?? '')
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // Auto-demo for screenshots
  if (new URLSearchParams(location.search).has('demo')) {
    setTimeout(() => runFullAnalysis(), 300);
  }
})();
