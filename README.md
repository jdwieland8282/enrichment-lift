# Enrichment Lift Demo (Prebid.js) — README

## Repo-specific quick steps (for this repository)

**GitHub repo:** `jdwieland8282/enrichment-lift`

### Move your existing local demo into this repo

**If your local project is already a git repo with history:**

```bash
git remote -v                       # see current remotes
git remote remove origin 2>/dev/null || true
# pick SSH or HTTPS
# SSH (recommended)
git remote add origin git@github.com:jdwieland8282/enrichment-lift.git
# or HTTPS
# git remote add origin https://github.com/jdwieland8282/enrichment-lift.git

git branch -M main
git push -u origin main
```

**If your local project is NOT a git repo yet:**

```bash
git init
git add .
git commit -m "Initial commit: enrichment-lift demo"
git branch -M main
# pick SSH or HTTPS
# SSH (recommended)
git remote add origin git@github.com:jdwieland8282/enrichment-lift.git
# or HTTPS
# git remote add origin https://github.com/jdwieland8282/enrichment-lift.git

git push -u origin main
```

Once pushed, update this README in the repo root.

This repo contains a minimal Prebid.js demo that exercises:

* **SharedID** (identity)
* **50% Enrichment Lift Measurement (ELM) suppression**
* At least one bidder adapter and a test creative render

If you’re just here to *run the demo*, start with **Quick Start**. If you want to publish this code to your own GitHub account, see **Move this code to your GitHub**.

---

## Quick Start

### Prerequisites

* Node.js **18+** and npm or pnpm/yarn
* A modern browser (Chrome/Edge/Firefox)
* Network access to the Prebid build you’re using (local or CDN)

### 1) Install dependencies

```bash
npm install
# or: pnpm i / yarn
```

### 2) Start a local web server

> Opening HTML from the filesystem (`file://`) breaks cookies and module loading. Always serve over `http://localhost`.

```bash
npm run dev
```

Then open the printed URL (usually [http://localhost:8080](http://localhost:8080)).

### 3) Verify the page loads

Open DevTools → **Console** and **Network**:

* You should see your Prebid build loading without 404s.
* After the auction, `pbjs.getBidResponses()` should return at least one bid for a test ad unit.
* If you’re sending a winning bid to the adserver creative, you should see the creative render.

---

## Configuration

### Prebid identity: SharedID

1. Make sure your Prebid build **includes the SharedID userId module**.
2. Confirm your config includes a `userSync.userIds` entry for `sharedId`.

```html
<script>
  window.pbjs = window.pbjs || {que: []};
  pbjs.que.push(function() {
    pbjs.setConfig({
      userSync: {
        userIds: [{
          name: 'sharedId',
          storage: {
            type: 'cookie',            // or 'html5'
            name: 'pbjs_sharedid',
            expires: 365
          }
          // params: { syncTime: 24 }  // optional, depending on your build
        }],
        syncDelay: 5000
      }
    });
  });
</script>
```

> **Tip:** In the console, check `pbjs.getConfig('userSync')` and look for `sharedId`. Also inspect `document.cookie` for `pbjs_sharedid` (or your chosen name). Consent/CMP settings, ITP, or strict browser privacy modes can prevent the ID from being written.

### 50% Enrichment Lift Measurement (ELM) suppression

Create a persistent, random 50/50 split and use it to toggle your enrichment logic. This keeps a stable cohort per browser.

```html
<script>
  (function initElmSuppression() {
    var KEY = 'elm_cohort_v1';
    var cohort = localStorage.getItem(KEY);
    if (!cohort) {
      cohort = Math.random() < 0.5 ? 'control' : 'treatment';
      localStorage.setItem(KEY, cohort);
    }
    window.__ELM__ = {
      cohort: cohort,
      enableEnrichment: cohort === 'treatment'
    };
    console.log('[ELM] cohort =', cohort, 'enableEnrichment =', __ELM__.enableEnrichment);
  })();

  // Example: gate an enrichment feature
  pbjs = window.pbjs || {que: []};
  pbjs.que = pbjs.que || [];
  pbjs.que.push(function() {
    if (window.__ELM__ && window.__ELM__.enableEnrichment) {
      // enable your enrichment settings here
      // e.g., pbjs.setConfig({ ortb2: { user: { data: [...] } } });
    }
  });
</script>
```

### Ad units & bidders

* Ensure your Prebid build **includes each bidder adapter** you reference in `adUnits`.
* Example (simplified):

```html
<script>
  pbjs = window.pbjs || {que: []};
  var adUnits = [{
    code: 'div-gpt-ad-300x250',
    mediaTypes: { banner: { sizes: [[300,250], [300,600]] } },
    bids: [
      { bidder: 'exampleBidder', params: { placementId: '12345' } }
    ]
  }];

  pbjs.que.push(function() {
    pbjs.addAdUnits(adUnits);
    pbjs.requestBids({
      timeout: 1000,
      bidsBackHandler: function() {
        // send targeting to ad server or directly render the winning ad
        var winner = pbjs.getHighestCpmBids('div-gpt-ad-300x250')[0];
        if (winner && winner.adId) {
          // Direct render path (for demo only)
          pbjs.renderAd(document.getElementById('ad-slot-300x250').contentWindow.document, winner.adId);
        }
      }
    });
  });
</script>
```

### Creative (adserver) render snippet (if you use GAM)

If you prefer ad-server based rendering, your GAM creative can be a small script that renders the Prebid ad using the ad ID passed via targeting.

```html
<script>
  try { pbjs.renderAd(document, '%%AD_ID%%'); }
  catch (e) { console.log('Prebid creative error', e); }
</script>
```

> Ensure your line item targeting sets `hb_adid` (or your macro) into `%%AD_ID%%`.

---

## Scripts

Commonly used npm scripts (adjust to your project):

```json
{
  "scripts": {
    "dev": "http-server -c-1 -p 8080 .",
    "lint": "eslint .",
    "build": "echo 'static demo'"
  },
  "devDependencies": {
    "http-server": "^14.1.1",
    "eslint": "^9.0.0"
  }
}
```

---

## Project structure

```
.
├─ index.html                # Demo page (includes Prebid + config)
├─ /src
│  ├─ adunits.js            # Ad unit definitions
│  ├─ enrichment.js         # ELM cohort logic
│  └─ prebid-config.js      # pbjs.setConfig, identity, etc.
├─ /public                   # Static assets
├─ package.json
└─ README.md
```

> Filenames are suggestions—align these with your actual repo.

---

## Troubleshooting

### SharedID never appears / always off

* Your Prebid build is missing the **SharedID userId module** → rebuild or switch to a build that includes it.
* Consent / CMP blocks storage → check your CMP flow; in strict modes the ID won't be set.
* Safari/ITP or privacy mode → try Chrome and verify over `http://localhost`.
* Ad/tracking blockers → test in a clean profile.

**Debug checks**

* `pbjs.getConfig('userSync')` shows `sharedId` entry.
* Cookie/localStorage contains your SharedID key (e.g., `pbjs_sharedid`).

### "Missing bidder adapter" or no bids

* Your Prebid build must include each bidder you configure in `adUnits`.
* Inspect console for messages like *adapter not found*.
* Confirm bidder params (e.g., `placementId`) are valid for the test endpoint.

### Creative doesn’t render

* If using GAM: confirm the correct macro (e.g., `%%AD_ID%%`) and that the line item targeting sends the right `hb_*` keys.
* If rendering directly, ensure you call `pbjs.renderAd(iframeDocument, adId)` **after** bids resolve and into a friendly iframe.

### General debugging tips

* Set `pbjs.setConfig({ debug: true })` to get verbose logs.
* In the console: `pbjs.getBidResponses()`, `pbjs.getAllWinningBids()`, `pbjs.getConfig()`.
* Watch Network → XHR for bidder requests/responses.

---

## .gitignore

Include at least:

```
node_modules
.DS_Store
.env
coverage
/dist
```

---

## License

Choose a license (MIT for permissive open source) or keep the repo private if it contains proprietary material.

---

## Move this code to your GitHub

### One-time setup (SSH optional)

* Ensure `git` is installed and you’ve logged in to GitHub.
* (Optional) \[Add your SSH key] so you can push via `git@` URLs.

### If this project is **not** already a git repo

```bash
git init
git add .
git commit -m "Initial commit: Prebid demo"
```

Create a new repo on GitHub (e.g., `prebid-demo`) and then:

```bash
git branch -M main
# Use SSH or HTTPS — pick one
git remote add origin git@github.com:<your-username>/prebid-demo.git
# or: git remote add origin https://github.com/<your-username>/prebid-demo.git

git push -u origin main
```

### If this project is already a git repo (local history exists)

Create the GitHub repo, then **replace** the current `origin` with your new repo:

```bash
git remote -v                 # see current remotes
git remote rename origin upstream   # keep the old remote as "upstream" (optional)

git remote add origin git@github.com:<your-username>/prebid-demo.git
# or HTTPS
# git remote add origin https://github.com/<your-username>/prebid-demo.git

git branch -M main
git push -u origin main
```

### Keep history but change repo name/visibility

* In GitHub: Settings → General → **Rename** the repository.
* Settings → **Danger Zone** → change visibility (Private/Public).

### Recommended repo settings

* **Default branch**: `main`
* **Branch protection**: require PRs + status checks (if you add CI)
* **Secrets**: do **not** commit API keys; use GitHub Actions secrets if needed

---

## (Optional) GitHub Actions — basic lint check

Add `.github/workflows/ci.yml`:

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm run lint
```

---

## Verification checklist

* [ ] `npm run dev` serves the page on `http://localhost:8080`
* [ ] Console shows `pbjs` loaded and `requestBids` completes
* [ ] `pbjs.getBidResponses()` contains at least one bid
* [ ] SharedID is present (cookie or localStorage) when allowed by consent
* [ ] ELM cohort logged (`control` or `treatment`) and enrichment toggled accordingly
* [ ] A creative renders (direct or via adserver)

---

## Need to tailor this to your exact demo?

Update the placeholder file names, bidder params, and any enrichment specifics in the snippets above so they match your repo. This README is designed to be drop-in and then customized in \~5 minutes.
