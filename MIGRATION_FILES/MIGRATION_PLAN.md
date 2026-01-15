# Migration plan (Executive summary)
Doc-Type: EXEC_SUMMARY
Purpose: decisions and rationale
Not a checklist. No step ordering.
Status: Plan only (no further file changes until User selects a phase)
Date: 2026-01-14
Owner: Dr. Voss
Repo baseline: openwebwork/renderer main
Version: 2026-01-14a
Last edited by: Codex
Scope: Executive summary; operational details live in `PLAN_NEXT_STEP.md`.
Audience + Use: Read this in 3 minutes to decide which phase to run.
Stop condition (decision gate): no file changes until a phase is selected.

## 1) Current state summary
- **Upstream-only:** 34 files (mostly structured asset pipeline, k8, RPC render templates). These are valuable and must not be lost.
- **Master-only:** 47 files (docs, scripts, tests, local helpers, flat public assets).
- **Common-but-different:** 18 files (root configs, templates, entrypoint script, and one doc) - high-impact and require review.
- Counts **exclude `lib/**`**, which will need a dedicated plan later.

## 2) Decision framework (simple rules)
**Master-only files**
- **Safe to port:** docs, scripts, tests, local helpers, private (developer ergonomics, low runtime risk).
- **Needs review:** flat `public/*` assets that compete with upstream pipeline.
- **Do not port (yet):** anything that would replace upstream pipeline sources without a mapping plan.

**Common-but-different files**
- **Keep upstream:** when file defines pipeline structure or upstream layout conventions.
- **Take master:** when file encodes local dev ergonomics and does not conflict with pipeline structure.
- **Manual merge:** when file is runtime-critical (templates, Dockerfile, render_app.conf, entrypoint script).
- **Manual merge scope:** never merge multiple template files in one go; merge **one template**, run the relevant page check, then proceed to the next.
- **Keep both:** if unclear, preserve upstream under `preserve/upstream/` and apply master version, then decide later.

**Legacy assets**
- Treat master's flat `public/*` as **legacy overrides**.
- Keep upstream pipeline **canonical** unless we explicitly map legacy files into pipeline sources.
- **Map only if needed:** map a legacy asset only when (a) a template still references it, or (b) it provides functionality missing from the upstream pipeline version.

## 3) Codex's proposed decisions (concrete choices)

### Master-only files (proposed)
**Port first (low risk, high value):**
- `docs/**` (USAGE, CODE_ARCHITECTURE, CHANGELOG, etc.)
- `script/**` (lint, smoke tests, dev env helpers)
- `tests/**` (python lint helpers)
- `run.sh`, `docker-compose.yml`, `cpanfile`, `devel/commit_changelog.py`
- `private/**` (local examples)

**Hold for review (legacy assets):**
- `public/*.css`, `public/*.js`, `public/*.png/svg` that reflect a flat layout
  - Keep, but **do not** replace upstream pipeline paths.
  - Quarantine in Phase C and map later if desired.

### Common-but-different files (clustered recommendations)
**Root configs:**
- `.gitignore`, `.dockerignore`, `.gitattributes` -> **take master**, low risk, improves ignores/linguist rules.
- `README.md` -> **take master**, high value documentation; preserve upstream copy first.
- `render_app.conf.dist` -> **take master**, safer defaults for local use; preserve upstream copy first.
- `Dockerfile` -> **manual merge** (risk: runtime deps and asset pipeline). Preserve upstream copy first.

**Entrypoint:**
- `script/render_app` -> **take master**, adds explicit `PERL5LIB` paths; preserve upstream copy first.

**Templates (high risk):**
- `templates/columns/*.html.ep`
- `templates/layouts/navbar.html.ep`
- `templates/pages/*.html.ep`
  - **Manual merge**: preserve upstream first, then apply master version only after review.

**Doc:**
- `docs/make_translation_files.md` -> **take master** (small diff).

### Upstream-only files that look "missing" in master
These are **not deletions**; they represent upstream pipeline and renderer infrastructure:
- `public/package.json`, `public/generate-assets.js`, `public/css/**`, `public/js/apps/**`
- `templates/RPCRenderFormats/*`
- `k8/*`, `conf/pg_config.yml`
Recommendation: **keep upstream versions as canonical**; do not replace with legacy flat assets.

## 4) Phases (conceptual only)

### Phase A - Low-risk additions (master-only)
**Scope:** docs, scripts, tests, local helpers; **exclude** any common-but-different files and legacy public assets.
**Risk:** low
**Output:** `PORT_NOTES.md` entries + updated `MASTER_ONLY_IMPORTED.txt`
**Pause point:** User reviews the added list before any merges.
**Acceptance check:** container builds (if applicable), renderer starts, one OPL page loads, one editor page loads.

### Phase B - Common-but-different review bundle (no merges)
**Scope:** 18 common files listed in `COMMON_DIFFS.md`.
**Risk:** medium/high
**Output:** one-paragraph decision note per file; no file replacements.
**Pause point:** User decides per-file action (keep upstream, take master, manual merge).
**Acceptance check:** after each template merge, re-run the same minimal checks (renderer starts, one OPL page loads, one editor page loads).

### Phase C - Legacy public assets handling
**Scope:** master flat `public/*` assets
**Risk:** high
**Output:** quarantine to `preserve/legacy-public/` + optional mapping plan into pipeline
**Pause point:** User chooses whether to map legacy assets into canonical pipeline paths.
**Acceptance check:** after quarantine (and after any mapping), re-run the minimal checks (renderer starts, one OPL page loads, one editor page loads).

### Phase D (future) - lib/** planning
**Scope:** lib/PG submodule management and any lib/ layout changes.
**Risk:** very high
**Output:** separate plan; no changes executed in current phases.

## 5) Logging
- **Single log file:** `PORT_NOTES.md` (append-only)
- Each entry records: file, action, source, reason, canonical vs legacy impact.

## 6) User-run git plan
A `codex_git_plan.sh` script will:
- Create a new branch from upstream (never touches master).
- Handle `lib/PG` as a submodule (gitlink) with upstream metadata.
- Commit one file at a time (including preserved snapshot pairs).
- Gate workflow commits behind `PUSH_WORKFLOWS=1`.

Note: `codex_git_plan.sh` is already present in `MIGRATION_FILES/`; update it only when a phase requires it.

Stop condition: After this plan is in place, Codex pauses until the User chooses the phase to execute.
