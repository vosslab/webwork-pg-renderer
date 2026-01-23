# UPSTREAM vs MASTER (Human-Readable Summary)

Date: 2026-01-14
Scope: filesystem comparison excluding `lib/`, `.git/`, `.cpanm/`, `local/`, `logs/`, `node_modules/`, and temp files (`.DS_Store`, `*.swp`, `*.swo`, `*.tmp`, `*.bak`).

## Executive Summary (Non-Coders)
- **Upstream** focuses on the core renderer product: its structured assets, build pipeline, and deployment files.
- **Master** focuses on local development and teaching workflows: richer docs, local scripts, and test helpers.
- We are **combining both**: keeping upstream structure and assets while adding master's dev tooling and documentation.
- **No upstream files are deleted by default.** If master replaces something, the upstream version is preserved in `preserve/upstream/`.

## What This Means in Practice (Non-Coders)
- You keep the official renderer layout and web assets from upstream.
- You also gain the more practical local workflows from master (run scripts, docs, smoke tests).
- If there is a conflict, both versions are saved so you can choose later.
- `lib/PG` is treated as a separate module (submodule), matching upstream's structure.

## Counts
- only-in-upstream: 34
- only-in-master: 47
- common-but-different: 18

## Top-Level Distribution
Only in upstream:
- public: 23
- k8: 3
- templates: 3
- (root): 2
- .github: 1
- conf: 1
- tmp: 1

Only in master:
- public: 19
- docs: 8
- (root): 7
- script: 5
- local_pg_files (renamed to `private/` in target): 3
- tests: 3
- .github: 1
- devel: 1

Common but different:
- templates: 10
- (root): 6
- docs: 1
- script: 1

## Notable Examples (Feature-Oriented)
Only in upstream (renderer-centric assets & pipeline):
- Asset pipeline layout: `public/css/**`, `public/js/apps/**`, `public/images/**`, `public/package.json`, `public/generate-assets.js`
- K8s files: `k8/Ingress.yml`, `k8/Renderer.yaml`, `k8/README.md`
- Templates: `templates/RPCRenderFormats/*`
- Config stub: `conf/pg_config.yml`
- Workflow: `.github/workflows/createContainer.yml`
- `Dockerfile_with_OPL`, `tmp/.gitkeep`

Only in master (local dev ergonomics & docs):
- Docs suite: `docs/USAGE.md`, `docs/CODE_ARCHITECTURE.md`, `docs/CHANGELOG.md`, etc.
- Dev/test tooling: `script/lint.sh`, `script/pg-smoke.pl`, `tests/run_pyflakes.sh`, `tests/check_ascii_compliance.py`
- Local helpers: `run.sh`, `docker-compose.yml`, `cpanfile`, `devel/commit_changelog.py`
- Local content: `local_pg_files/*.pg` (renamed to `private/*.pg` in target)
- Static assets (flat layout): `public/pg-modern.css`, `public/navbar.js`, `public/webwork_logo.svg`, etc.

Common but different (high-impact overlays):
- Root: `.gitignore`, `.dockerignore`, `.gitattributes`, `Dockerfile`, `README.md`, `render_app.conf.dist`
- Script: `script/render_app`
- Templates: `templates/columns/*.html.ep`, `templates/layouts/navbar.html.ep`, `templates/pages/*.html.ep`
- Docs: `docs/make_translation_files.md`

## Structure Note: lib/PG as a Module (Submodule)
- Upstream represents `lib/PG` as a git submodule (gitlink) with:
  - `path = lib/PG`
  - `url = https://github.com/openwebwork/pg.git`
  - `branch = main`
- Master may contain `lib/PG` as a normal directory; that content is **not** copied.
- The target superproject will keep `lib/PG` as a submodule to preserve upstream modular structure.

## Feature Lens (Quick Take)
Upstream emphasizes:
- Asset pipeline and structured public assets
- Renderer-native templates and RPC render formats
- K8s deployment artifacts

Master emphasizes:
- Local developer experience (scripts, docs, smoke tests)
- Flat public asset layout and UI tweaks
- Local content scaffolding (`local_pg_files/`, renamed to `private/` in target)
