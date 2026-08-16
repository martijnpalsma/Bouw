# AGENTS.md

## Cursor Cloud specific instructions

This repo is a **static, client-only web app** (no backend, no build step, no package manager). It is a Dutch building/insurance risk-inventory tool made of three standalone HTML files:

- `index.html` — landing page / navigation
- `gebouw-formulier.html` — "Risico Inventarisatie Formulier" (multi-section building form)
- `bouw-informatie-systeem.html` — inspection/overview UI with modals, `localStorage` persistence, and jsPDF report export

### Running

There is no dependency install and no build. Serve the files over HTTP (do not open via `file://`, so CDN scripts and relative links behave):

```
python3 -m http.server 8080
```

Then open `http://localhost:8080/index.html`.

### Notes / gotchas

- **jsPDF is loaded from a CDN** (`cdnjs.cloudflare.com`) at runtime, so PDF report generation on `bouw-informatie-systeem.html` requires internet access. Without network, the page still loads but "Genereer PDF Rapport" will fail.
- Data entered in the "Verzekerde"/"Elektra" modals is persisted only in the browser's `localStorage` (keys `verzekerdeData`, `elektraData`); there is no server persistence.
- There are **no lint, test, or build tooling** in this repo. "Testing" means manually loading the pages in a browser and exercising the form/modal/PDF flow.
