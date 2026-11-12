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

      const water = OpenData.schatWatervoorziening(true);
      const fotoHints = RiskEngine.demoFotoHints(functie);
      if (selectedFile) {
        fotoHints.gevel = 'Foto geüpload — visuele AI-analyse optioneel via Flask; checklist hieronder is leidend.';
      }

      loadingText.textContent = 'Bouwt risicodeskundige rapportage…';
      const report = RiskEngine.buildReport({
        locatie, pand, brandweer, water, functie, fotoHints, antwoorden: extraAnswers
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

  function renderReport(r) {
    const L = r.locatie || {};
    const P = r.pand || {};
    const B = r.brandweer || {};
    const nearest = B.nearest;
    const water = B.water || {};

    const groups = {};
    (r.topics || []).forEach(t => {
      groups[t.group] = groups[t.group] || [];
      groups[t.group].push(t);
    });

    results.innerHTML = `
      <div class="risk-banner ${r.niveau}">
        <div>
          <div style="opacity:.85;font-size:.78rem;text-transform:uppercase;letter-spacing:.06em">Risiconiveau</div>
          <strong>${r.niveau.toUpperCase()}</strong>
          <div style="opacity:.9;font-size:.85rem;margin-top:.25rem">${escapeHtml(L.weergavenaam || '')} · ${escapeHtml(r.functie || '')}</div>
        </div>
        <div class="score">${r.score}</div>
      </div>

      <div class="section open">
        <div class="section-head" onclick="this.parentElement.classList.toggle('open')"><h3>📍 Locatie & BAG</h3><span>▾</span></div>
        <div class="section-body">
          <dl class="kv">
            <dt>Adres</dt><dd>${escapeHtml(L.weergavenaam || '—')}</dd>
            <dt>Buurt / wijk</dt><dd>${escapeHtml([L.buurt, L.wijk].filter(Boolean).join(' · ') || '—')}</dd>
            <dt>Gemeente</dt><dd>${escapeHtml([L.gemeente, L.provincie].filter(Boolean).join(', ') || '—')}</dd>
            <dt>Waterschap</dt><dd>${escapeHtml(L.waterschap || '—')}</dd>
            <dt>Perceel</dt><dd>${escapeHtml((L.perceel || []).join(', ') || '—')}</dd>
            <dt>Coördinaten</dt><dd>${L.lat != null ? `${L.lat.toFixed(5)}, ${L.lon.toFixed(5)}` : '—'}</dd>
            <dt>Bron</dt><dd><span class="chip source">${escapeHtml(L.bron || '')}</span></dd>
          </dl>
          ${P.bouwjaar ? `
          <h4 style="font-size:.85rem;margin:.5rem 0">Pand (BAG WFS)</h4>
          <dl class="kv">
            <dt>Bouwjaar</dt><dd>${P.bouwjaar}${r.age != null ? ` (±${r.age} jaar)` : ''}</dd>
            <dt>Status</dt><dd>${escapeHtml(P.status || '—')}</dd>
            <dt>Oppervlakte</dt><dd>${P.oppervlakte_min ?? '?'} – ${P.oppervlakte_max ?? '?'} m²</dd>
            <dt>VBO’s</dt><dd>${P.aantal_verblijfsobjecten ?? '—'}</dd>
            <dt>Gebruiksdoel</dt><dd>${escapeHtml((P.gebruiksdoel || []).join(', ') || '—')}</dd>
            <dt>Bron</dt><dd><span class="chip source">${escapeHtml(P.bron || '')}</span></dd>
          </dl>` : '<p class="muted">Geen pand gevonden in BAG WFS voor dit punt.</p>'}
        </div>
      </div>

      <div class="section open">
        <div class="section-head" onclick="this.parentElement.classList.toggle('open')"><h3>🏗️ Materialen & isolatie</h3><span>▾</span></div>
        <div class="section-body">
          <div class="chips">
            ${(r.materialen?.gevel || []).map(m => `<span class="chip">${escapeHtml(m)}</span>`).join('')}
            ${(r.materialen?.dak || []).map(m => `<span class="chip">${escapeHtml(m)}</span>`).join('')}
            ${(r.materialen?.kozijnen || []).map(m => `<span class="chip">${escapeHtml(m)}</span>`).join('')}
          </div>
          <div class="chips">
            ${(r.materialen?.isolatie || []).map(m => `<span class="chip ok">${escapeHtml(m)}</span>`).join('')}
            ${(r.materialen?.gebruiksdoel_bag || []).map(m => `<span class="chip source">${escapeHtml(m)}</span>`).join('')}
          </div>
        </div>
      </div>

      <div class="section open">
        <div class="section-head" onclick="this.parentElement.classList.toggle('open')"><h3>🚒 Brandweer & repressie</h3><span>▾</span></div>
        <div class="section-body">
          ${nearest ? `
          <dl class="kv">
            <dt>Kazerne</dt><dd>${escapeHtml(nearest.name)} (${escapeHtml(nearest.type)})</dd>
            <dt>Afstand</dt><dd>${nearest.distance_km} km</dd>
            <dt>Opkomst 1e TS</dt><dd>±${nearest.duration_min} min</dd>
            <dt>Risicoklasse</dt><dd>${escapeHtml(B.riskClass || '')}</dd>
            <dt>Bron</dt><dd><span class="chip source">${escapeHtml(nearest.bron || '')}</span></dd>
          </dl>
          <p class="muted" style="margin-bottom:.6rem">${escapeHtml(nearest.address || '')}</p>
          ${(B.stations || []).slice(1, 4).map(s =>
            `<div class="muted" style="padding:.25rem 0">+ ${escapeHtml(s.name)} · ${s.distance_km} km · ±${s.duration_min} min</div>`
          ).join('')}` : '<p>Geen kazerne gevonden in OSM voor dit gebied.</p>'}

          <h4 style="font-size:.85rem;margin:1rem 0 .4rem">💧 Watervoorziening</h4>
          ${(water.items || []).map(w => `
            <div style="padding:.45rem 0;border-bottom:1px solid var(--line);font-size:.86rem">
              <strong>${escapeHtml(w.type)}</strong> — ${escapeHtml(w.location)} · ${escapeHtml(w.distance)} · ${escapeHtml(w.capacity)}<br>
              <span class="muted">Toegang: ${escapeHtml(w.accessibility)} · zekerheid ${escapeHtml(w.zekerheid || '')}</span>
            </div>`).join('')}
          <div class="chips" style="margin-top:.6rem">
            ${(water.aandacht || []).map(a => `<span class="chip warn">${escapeHtml(a)}</span>`).join('')}
          </div>
          <p class="muted" style="margin-top:.5rem">Bron water: ${escapeHtml(water.bron || '')}</p>
        </div>
      </div>

      ${Object.entries(groups).map(([group, items]) => `
        <div class="section ${group === 'Brand' || group === 'Speciaal risico' ? 'open' : ''}">
          <div class="section-head" onclick="this.parentElement.classList.toggle('open')">
            <h3>📋 ${escapeHtml(group)}</h3><span>▾</span>
          </div>
          <div class="section-body">
            <ul class="checklist">
              ${items.map(t => `
                <li>
                  <span>${statusIcon[t.status] || '❔'}</span>
                  <div><strong>${escapeHtml(t.name)}</strong><br><span class="muted">${escapeHtml(t.note || '')}</span></div>
                  <span class="status ${t.status}">${statusLabel[t.status] || t.status}</span>
                </li>`).join('')}
            </ul>
          </div>
        </div>`).join('')}

      <div class="section open">
        <div class="section-head" onclick="this.parentElement.classList.toggle('open')"><h3>💶 Taxatie</h3><span>▾</span></div>
        <div class="section-body">
          <dl class="kv">
            <dt>Herbouw</dt><dd>${escapeHtml(r.taxatie?.herbouwwaarde_indicatie || '')}</dd>
            <dt>Inventaris</dt><dd>${escapeHtml(r.taxatie?.inventaris || '')}</dd>
            <dt>Bedrijfsschade</dt><dd>${escapeHtml(r.taxatie?.bedrijfsschade || '')}</dd>
          </dl>
          <div class="chips">
            ${(r.taxatie?.premie_drivers || []).map(p => `<span class="chip warn">${escapeHtml(p)}</span>`).join('')}
          </div>
          <p style="margin-top:.75rem;font-size:.9rem">${escapeHtml(r.conclusie || '')}</p>
        </div>
      </div>

      <div class="questions">
        <h3>❓ Wat de risicodeskundige nog wil weten</h3>
        ${(r.vragen || []).map(q => `
          <div class="q-item">
            ${q.prioriteit === 'hoog' ? '<span class="prio">PRIORITEIT</span>' : ''}
            <strong>${escapeHtml(q.vraag)}</strong>
            <small>${escapeHtml(q.reden)}</small>
          </div>`).join('')}

        <div class="answer-grid" id="answerGrid">
          ${(r.vragen || []).slice(0, 6).map(q => `
            <label>${escapeHtml(q.vraag)}
              <input data-qid="${escapeHtml(q.id)}" placeholder="Jouw antwoord…">
            </label>`).join('')}
        </div>
        <div class="btn-row">
          <button class="btn-ember" id="refineBtn">Verfijn met antwoorden</button>
        </div>
      </div>

      <p class="footer-meta">
        Gegenereerd ${escapeHtml(r.timestamp || '')} · lokaal · bronnen: BAG/PDOK, OSM, RiskWalk-checklist
      </p>
    `;

    results.classList.add('show');
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
