# AGENTS.md

## Cursor Cloud specific instructions

### What this is
A dependency-free, **static** web app ("Bouw Informatie Systeem", Dutch) consisting of three standalone HTML files: `index.html` (home/navigation), `gebouw-formulier.html` (building data-entry form), and `bouw-informatie-systeem.html` (overview with insured-party/electrical sections). There is **no backend, no database, and no build step**. Data is persisted in the browser via `localStorage` (keys such as `verzekerdeData`, `elektraData`).

### Running (dev)
There is no dev/build/test/lint tooling. Serve the folder with any static server and open the pages in a browser:

```bash
python3 -m http.server 8000   # then open http://localhost:8000/index.html
```

Prefer serving over `http://` rather than opening `file://` so relative navigation between pages behaves consistently.

### Tests / lint / build
None exist (no test framework, no linter config, no bundler). Nothing to install or build.

### Gotchas
- Third-party libraries load from CDNs (jsPDF, jsPDF-AutoTable), so PDF export requires internet access; pages still load and forms still work offline.
- The Google Maps widget uses a hardcoded `YOUR_GOOGLE_MAPS_API_KEY` placeholder in `gebouw-formulier.html` and `bouw-informatie-systeem.html`; the map won't render without a real key, but nothing else depends on it.
- Data lives only in the current browser's `localStorage`; clearing site data wipes all entries.
