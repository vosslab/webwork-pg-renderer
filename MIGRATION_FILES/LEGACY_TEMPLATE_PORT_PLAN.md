# Legacy template port plan (filesystem audit)

Date: 2026-01-15
Doc-Type: LEGACY_TEMPLATE_PORT_PLAN
Status: Decision: keep canonical templates; no merge planned
Scope: legacy templates in `preserve/legacy-templates/templates/*`

## A. Summary
- Total legacy files: 10
- Mapped to canonical destinations: 10
- Unmapped: 0
- Identical to canonical: 0
- Binary files skipped: 0
- Recommendation counts:
  - KEEP CANONICAL (NO MERGE): 10
  - ALREADY PROMOTED (IDENTICAL) -> IGNORE: 0
  - KEEP QUARANTINED (BINARY): 0

## B. Mapping table

| Legacy file | Proposed canonical destination | Exists in canonical? | Identical? | Recommendation |
|---|---|---|---|---|
| `preserve/legacy-templates/templates/layouts/navbar.html.ep` | `templates/layouts/navbar.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/columns/editorUI.html.ep` | `templates/columns/editorUI.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/columns/editorIframe.html.ep` | `templates/columns/editorIframe.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/columns/filebrowser.html.ep` | `templates/columns/filebrowser.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/columns/oplIframe.html.ep` | `templates/columns/oplIframe.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/columns/tags.html.ep` | `templates/columns/tags.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/pages/twocolumn.html.ep` | `templates/pages/twocolumn.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/pages/flex.html.ep` | `templates/pages/flex.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/pages/oplUI.html.ep` | `templates/pages/oplUI.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |
| `preserve/legacy-templates/templates/exception.html.ep` | `templates/exception.html.ep` | yes | no | KEEP CANONICAL (NO MERGE) |

## C. Decision notes (KEEP CANONICAL)

### `preserve/legacy-templates/templates/layouts/navbar.html.ep`
- Canonical keeps baseURL-safe asset paths and `<base href>`.
- Canonical dropdown options are `Static`, `Default`, `Debug` (desired).
- Canonical seed defaults are handled in `public/js/navbar.js`.
- Legacy adds jQuery/jQuery UI assets, but no current templates use jQuery UI widgets.

### `preserve/legacy-templates/templates/columns/editorUI.html.ep`
- Canonical uses CodeMirror 6 via `@openwebwork/pg-codemirror-editor`.
- Legacy embeds CodeMirror 5 assets and inline PGML defaults, which would reintroduce
  legacy asset paths and duplicate editor logic.

### `preserve/legacy-templates/templates/columns/editorIframe.html.ep`
- Canonical uses baseURL-safe assets and npm-managed iframe-resizer.
- Legacy uses root-absolute assets and exposes `showHints`/`showSolutions`, which are
  not part of the current UI intent.

### `preserve/legacy-templates/templates/columns/filebrowser.html.ep`
- Canonical uses baseURL-safe asset paths and relative endpoints.
- Legacy uses root-absolute assets and endpoints.

### `preserve/legacy-templates/templates/columns/oplIframe.html.ep`
- Canonical uses baseURL-safe assets and npm-managed iframe-resizer.
- Legacy uses root-absolute assets.

### `preserve/legacy-templates/templates/columns/tags.html.ep`
- Canonical reads taxonomy from `tmp/tagging-taxonomy.json` and logs if missing.
- Legacy reads taxonomy from `$ENV{WEBWORK_ROOT}/htdocs/DATA/tagging-taxonomy.json`.
  Canonical behavior is preferred for portability.

### `preserve/legacy-templates/templates/pages/twocolumn.html.ep`
- Canonical uses baseURL-safe `css/twocolumn.css`.
- Legacy uses root-absolute `/twocolumn.css`.

### `preserve/legacy-templates/templates/pages/flex.html.ep`
- Canonical uses baseURL-safe `css/opl-flex.css`.
- Legacy uses root-absolute `/opl-flex.css`.

### `preserve/legacy-templates/templates/pages/oplUI.html.ep`
- Canonical uses baseURL-safe `css/opl-flex.css`.
- Legacy uses root-absolute `/opl-flex.css`.

### `preserve/legacy-templates/templates/exception.html.ep`
- Canonical uses baseURL-safe asset paths and strips `$ENV{RENDER_ROOT}` from messages.
- Legacy uses `$ENV{SITE_HOST}` for asset URLs and fixed typing speed.

## D. Guardrails

- Do not introduce root-absolute asset paths; keep baseURL-safe references.
- Skip binary assets (`.png`, `.svg`) if any are added to this legacy set later.
- Avoid reintroducing legacy vendor JS/CDN includes if npm assets are already used.
- No changes performed in this step; plan only.
