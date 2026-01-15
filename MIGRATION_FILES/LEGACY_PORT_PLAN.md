# Legacy Port Plan (Filesystem Audit)

Date: 2026-01-14
Doc-Type: LEGACY_PORT_PLAN
Status: Draft (plan only; no changes executed)
Scope: legacy assets in preserve/legacy-public/public/*

## A. Summary
- Total legacy files: 19
- Mapped to canonical destinations: 19
- Unmapped: 0
- Recommendation counts:
  - PROMOTE NOW: 3
  - PROMOTE LATER: 2
  - KEEP QUARANTINED: 6
  - ALREADY PROMOTED (IDENTICAL) -> IGNORE: 8

## B. Mapping table

| Legacy file | Proposed canonical destination | Exists in canonical? | Referenced today? | Recommendation |
|---|---|---|---|---|
| `preserve/legacy-public/public/Rederly-50.png` | `public/images/Rederly-50.png` | no | no | KEEP QUARANTINED |
| `preserve/legacy-public/public/crt-display.css` | `public/css/crt-display.css` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/favicon.ico` | `public/images/favicon.ico` | yes | yes | KEEP QUARANTINED |
| `preserve/legacy-public/public/filebrowser.css` | `public/css/filebrowser.css` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/filebrowser.js` | `public/js/filebrowser.js` | yes | yes | PROMOTE LATER |
| `preserve/legacy-public/public/iframeResizer.contentWindow.map` | `public/js/iframeResizer.contentWindow.map` | no | no | KEEP QUARANTINED |
| `preserve/legacy-public/public/iframeResizer.contentWindow.min.js` | `public/js/iframeResizer.contentWindow.min.js` | no | no | KEEP QUARANTINED |
| `preserve/legacy-public/public/iframeResizer.map` | `public/js/iframeResizer.map` | no | no | KEEP QUARANTINED |
| `preserve/legacy-public/public/iframeResizer.min.js` | `public/js/iframeResizer.min.js` | no | yes | KEEP QUARANTINED |
| `preserve/legacy-public/public/navbar.css` | `public/css/navbar.css` | yes | yes | PROMOTE NOW |
| `preserve/legacy-public/public/navbar.js` | `public/js/navbar.js` | yes | yes | PROMOTE LATER |
| `preserve/legacy-public/public/opl-flex.css` | `public/css/opl-flex.css` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/pg-modern.css` | `public/css/pg-modern.css` | yes | no | PROMOTE NOW (UNUSED BY DEFAULT) |
| `preserve/legacy-public/public/tags.css` | `public/css/tags.css` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/tags.js` | `public/js/tags.js` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/twocolumn.css` | `public/css/twocolumn.css` | yes | yes | PROMOTE NOW |
| `preserve/legacy-public/public/typing-sim.css` | `public/css/typing-sim.css` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/webwork-logo-65.png` | `public/images/webwork-logo-65.png` | yes | yes | ALREADY PROMOTED (IDENTICAL) -> IGNORE |
| `preserve/legacy-public/public/webwork_logo.svg` | `public/images/webwork_logo.svg` | yes | no | ALREADY PROMOTED (IDENTICAL) -> IGNORE |

## C. Per-file notes (PROMOTE NOW / PROMOTE LATER)

### `preserve/legacy-public/public/filebrowser.js` -> `public/js/filebrowser.js`
- Line count: legacy 195 vs canonical 197.
- Dependency signals: render_api, hardcoded_root.
- Diff highlights:
  - Legacy uses absolute `/render-api/` while canonical uses relative `render-api/`.
  - Legacy swaps `_format=json` + `isInstructor=1` + `forceScaffoldsOpen=1` for `format=json` + `permissionLevel=20`.
- Referenced by: templates/columns/filebrowser.html.ep.
- Risk: medium; requires review for baseURL/route safety or template changes.
- Verify: test with baseURL prefix and check /render-api and editor/filebrowser flows.

### `preserve/legacy-public/public/navbar.css` -> `public/css/navbar.css`
- Line count: legacy 352 vs canonical 155.
- Signals: legacy defines CSS variables (:root).
- Diff highlights:
  - Legacy introduces CSS variables and a modernized navbar layout (spacing, typography, hover states).
  - Adds styles for `#iframe-header` and related controls.
- Selector check: `templates/columns/editorIframe.html.ep` includes `id="iframe-header"` and class `iframe-header`.
- Referenced by: templates/layouts/navbar.html.ep.
- Risk: low (CSS-only or simple JS), but verify UI renders and no baseURL regressions.
- Verify: load `/`, ensure navbar/filebrowser/tags/OPL layout renders and no missing assets.

### `preserve/legacy-public/public/navbar.js` -> `public/js/navbar.js`
- Line count: legacy 254 vs canonical 292.
- Dependency signals: render_api, hardcoded_root.
- Diff highlights:
  - Legacy adds default template selection and random seed initialization on load.
  - Legacy uses absolute `/render-api/...` routes; canonical uses relative `render-api/...` for baseURL safety.
  - Legacy removes the postMessage logging block found in canonical.
- Referenced by: templates/layouts/navbar.html.ep.
- Risk: medium; requires review for baseURL/route safety or template changes.
- Verify: test with baseURL prefix and check /render-api and editor/filebrowser flows.

### `preserve/legacy-public/public/pg-modern.css` -> `public/css/pg-modern.css`
- Line count: legacy 87; canonical file now exists (unused by default).
- Diff highlights:
  - Optional theme file; introduces a modern button/theme palette via CSS variables.
- Not referenced by current templates/public JS; promotion requires template inclusion.
- Risk: medium; requires review for baseURL/route safety or template changes.
- Verify: test with baseURL prefix and check /render-api and editor/filebrowser flows.

### `preserve/legacy-public/public/twocolumn.css` -> `public/css/twocolumn.css`
- Line count: legacy 94 vs canonical 98.
- Diff highlights:
  - Legacy replaces `.iframe-header` rules with a new `#iframe-header` layout and styling.
- Selector check: `templates/columns/editorIframe.html.ep` includes `id="iframe-header"` and class `iframe-header`.
- Referenced by: templates/pages/twocolumn.html.ep.
- Risk: low (CSS-only or simple JS), but verify UI renders and no baseURL regressions.
- Verify: load `/`, ensure navbar/filebrowser/tags/OPL layout renders and no missing assets.

## D. Guardrails
- Do not reintroduce flat asset references in templates.
- Do not promote vendor/minified third-party bundles unless you explicitly stop using the npm pipeline for them.
- No changes performed in this step; plan only.
- Decision rule: when multiple styling options are viable, default to the modern styling.

## E. Diff notes for other non-identical legacy assets (KEEP QUARANTINED)

### `preserve/legacy-public/public/Rederly-50.png` -> `public/images/Rederly-50.png`
- Canonical destination does not exist.
- Binary asset (4,072 bytes); not referenced in templates/public JS.
- Recommendation: KEEP QUARANTINED (unused asset).

### `preserve/legacy-public/public/favicon.ico` -> `public/images/favicon.ico`
- Binary differs from canonical favicon (not identical).
- Referenced by: templates/RPCRenderFormats/default.html.ep, templates/RPCRenderFormats/default.json.ep (current repo).
- Recommendation: KEEP QUARANTINED unless you prefer the legacy icon; swapping icons is cosmetic.

### `preserve/legacy-public/public/iframeResizer.min.js` -> `public/js/iframeResizer.min.js`
- Vendor/minified JS; canonical destination does not exist (pipeline likely provides via npm).
- Referenced by: templates/columns/oplIframe.html.ep, templates/columns/editorIframe.html.ep.
- Recommendation: KEEP QUARANTINED (avoid bypassing npm pipeline).

### `preserve/legacy-public/public/iframeResizer.map` -> `public/js/iframeResizer.map`
- Vendor source map; canonical destination does not exist.
- Recommendation: KEEP QUARANTINED.

### `preserve/legacy-public/public/iframeResizer.contentWindow.min.js` -> `public/js/iframeResizer.contentWindow.min.js`
- Vendor/minified JS; canonical destination does not exist.
- Recommendation: KEEP QUARANTINED.

### `preserve/legacy-public/public/iframeResizer.contentWindow.map` -> `public/js/iframeResizer.contentWindow.map`
- Vendor source map; canonical destination does not exist.
- Recommendation: KEEP QUARANTINED.

## F. Appendix: selector and string-literal audits

### F1) CSS selector audit (templates)
Grep results in `templates/**` for selectors referenced in legacy CSS:
- `#iframe-header`: `templates/columns/editorIframe.html.ep`
- `.iframe-header`: `templates/columns/editorIframe.html.ep`

Interpretation:
- These selectors are present in templates, so the legacy iframe-header styling should apply without template changes.
- Before promotion, confirm DOM structure in rendered pages matches `editorIframe` output (or update templates to match, which is out of scope for this plan).

### F2) JS string-literal audit (legacy vs canonical)
Root-absolute literals found in legacy JS (pattern `['"]/`):

| File | Literal | Count | Proposed replacement |
|---|---|---:|---|
| `preserve/legacy-public/public/navbar.js` | `/render-api` | 2 | `render-api` |
| `preserve/legacy-public/public/navbar.js` | `/render-api/can` | 1 | `render-api/can` |
| `preserve/legacy-public/public/navbar.js` | `/render-api/tap` | 1 | `render-api/tap` |
| `preserve/legacy-public/public/filebrowser.js` | `/render-api/` | 1 | `render-api/` |

Canonical JS currently uses relative paths:
- `public/js/navbar.js`: `render-api`, `render-api/can`, `render-api/tap`
- `public/js/filebrowser.js`: `render-api/`

Gate for JS promotion (explicit):
- Replace legacy root-absolute strings with baseURL-safe equivalents **before** promotion.

After replacement, verify:
- baseURL prefix mode works (non-empty baseURL)
- `/render-api` POST endpoints still function

## G. Promotion notes (this pass)

### `public/css/navbar.css` (modernized navbar + iframe header styling)
- Strategy: take legacy navbar styling and **rewrite** `#iframe-header` selectors to `.iframe-header` to avoid ID-specific overrides.
- Change: adopt modern layout, CSS variables, and button styling; selector specificity kept class-based.
- BaseURL safety: not applicable (CSS only).
- API parameters: not applicable.

### `public/js/filebrowser.js` (best-of merge)
- Strategy: **manual cherry-pick** (baseURL hardening only); legacy parameter changes dropped to preserve canonical semantics.
- Change: normalize `target` to strip leading `/` before fetch (baseURL safety hardening).
- BaseURL safety: **no** `"/render-api"` literals remain in canonical JS.
- API parameters: **no changes** (kept canonical `_format`, `isInstructor`, `forceScaffoldsOpen`, `includeTags`).

### `public/js/navbar.js` (best-of merge)
- Strategy: **manual cherry-pick** (legacy UX defaults only); keep canonical logging and route construction.
- Change: add default template selection and seed initialization (legacy UX), reuse existing selection handler.
- BaseURL safety: **no** `"/render-api"` literals remain in canonical JS.
- API parameters: **no changes** (kept canonical request payloads and relative routes).

### `public/css/pg-modern.css` (optional theme)
- Change: added as an unused theme file with a top comment indicating it is not active by default.
- BaseURL safety: not applicable (CSS only).
- API parameters: not applicable.

### `public/css/twocolumn.css` (modernized iframe header layout)
- Strategy: port legacy iframe header layout and **rewrite** `#iframe-header` selectors to `.iframe-header`.
- Change: update header container and render-option layout to the modern style.
- BaseURL safety: not applicable (CSS only).
- API parameters: not applicable.
