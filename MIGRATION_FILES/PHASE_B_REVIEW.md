# Phase B Review Bundle (Common-but-different files)

Date: 2026-01-14
Scope: Upstream vs master-link comparison for the 18 common-but-different files in `COMMON_DIFFS.md`.
Output: One short "decision needed" note per file (or dependency notes where requested). No merges or overwrites performed.

## Global rule
Upstream routing, baseURL behavior, and the upstream asset pipeline stay canonical. Do not introduce flat root assets (`/foo.js`) or `/webwork2_files/...` assumptions until Phase C asset mapping exists.

## Decisions finalized (low risk)

1) `.dockerignore`
Decision: take master.
Reason: low risk; ignores `node_modules` to reduce build context.

2) `.gitattributes`
Decision: keep upstream for now (low priority).
Reason: repo metadata only; does not block Phase C. If you later want Linguist vendoring for `lib/WeBWorK/htdocs/**`, it remains harmless.

3) `.gitignore`
Decision: manual merge.
Rules: keep upstream ignores for canonical pipeline outputs; add master ignores for dev caches and local artifacts (`.cpan*`, `local/`, editor temp files); avoid broad patterns that hide real changes (prefer `logs/*.log` to `logs/*` unless justified).

5) `README.md`
Decision: keep upstream as top-level, add a "Local dev on this fork" section from master.
Reason: upstream API semantics remain authoritative; fork guidance stays discoverable.

6) `docs/make_translation_files.md`
Decision: keep upstream for now; adjust later to match current layout.
Reason: master paths likely reflect an older tree.

7) `templates/columns/oplIframe.html.ep`
Decision: keep upstream pipeline asset paths.

8) `templates/exception.html.ep`
Decision: keep upstream for baseURL correctness; cosmetic tweaks optional later.

9) `templates/pages/flex.html.ep`
Decision: keep upstream pipeline paths.

10) `templates/pages/oplUI.html.ep`
Decision: keep upstream pipeline paths.

11) `templates/pages/twocolumn.html.ep`
Decision: keep upstream pipeline paths.

## High impact files (decisions constrained by dependency notes)

4) `Dockerfile`
Decision: manual merge with hard constraint: preserve upstream pipeline steps.
Concrete choices:
- Keep upstream npm install in `public/` and `lib/PG/htdocs`.
- Do not add any step requiring `lib/WeBWorK/htdocs` (not present upstream).
- Fix `pg_config.yml` placement to `lib/PG/conf/pg_config.yml` (or ensure it exists at runtime).
- Optionally take master's newer base image and cpanfile flow.

7) `render_app.conf.dist`
Decision: keep upstream defaults canonical and stop changing them.
- `baseURL = ''`
- `formURL = '/render-api'`
- Keep the relative-to-absolute resolver; do not change the default path again until templates/clients settle.

8) `script/render_app`
Decision: implement the minimal deterministic `@INC` list for current layout.
- Add `../lib`, `../lib/PG`, `../lib/PG/lib`, `../lib/WeBWorK`.
- Do not add `lib/WeBWorK/lib` unless you vendor full WeBWorK later.

9) `templates/columns/editorIframe.html.ep`
Decision: keep upstream until Phase C mapping.
Reason: master introduces flat root assets that ignore `baseURL`.

10) `templates/columns/editorUI.html.ep`
Decision: keep upstream editor core.
Optional later: port only the default PGML example content into upstream UI.
Reason: master assumes `/webwork2_files/...` which does not exist upstream.

11) `templates/columns/filebrowser.html.ep`
Decision: keep upstream.
Reason: master hardcodes `/render-api/...` and flat assets, which breaks proxy `baseURL`.

12) `templates/columns/tags.html.ep`
Decision: staged manual merge, direction set now.
- Keep upstream asset pipeline paths.
- Adopt tolerant taxonomy behavior: if taxonomy file missing, default to empty list and continue.
- Log a warning when missing to surface misconfig.

15) `templates/layouts/navbar.html.ep`
Decision: keep upstream. Keep `<base href="$main::basehref">`.
Reason: base tag is essential for proxy correctness; master assets are flat and `/webwork2_files/...` dependent.

## Phase C boundary
Phase C is where legacy flat `public/*` assets are quarantined and any mapping into the canonical pipeline is decided. No template should switch to flat `/asset.js` paths before that mapping exists.

## Validation gate (post-Dockerfile merge and post-Phase C)
Run these 3-5 checks after Dockerfile merge and again after Phase C:\n
1) Confirm `lib/PG/conf/pg_config.yml` exists inside the container.\n
2) Confirm one pipeline asset URL returns 200 (e.g., a `public/` or `pg_files` asset).\n
3) Confirm `/health` returns 200.\n
4) Confirm one render request succeeds for `private/myproblem.pg` (POST `/` or `/render-api`).\n

## Completion rule
Phase B is complete when every item above is either a firm decision with 1-2 sentence rationale or a dependency note with a recommended patch plan. No files merged in Phase B.
