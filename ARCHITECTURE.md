# Architecture Overview

This repo’s sole purpose is to locally render and test WeBWorK PG/PGML problems. It is not a full WeBWorK stack; deployment artifacts (e.g., k8 manifests) are optional and not maintained as first-class targets.

## High-Level Layout
- **Entry & Routing**: `script/render_app` boots Mojolicious. `lib/RenderApp.pm` wires routes, helpers, env defaults, and passes requests to controllers.
- **App Logic**: `lib/RenderApp/Controller/*` handles endpoints. `RenderProblem` orchestrates rendering; `IO` covers file reads/writes/uploads/search; `FormatRenderedProblem` shapes HTML output per template.
- **Domain Model**: `lib/RenderApp/Model/Problem` abstracts a PG problem (paths, contents, seed, render/save).
- **PG Engine**: `lib/PG` and `lib/WeBWorK` bundle the math rendering engine/macros (including TikZ support). Treat as vendor code unless you know PG internals.
- **UI**: `templates/` (navbar/layout) + `public/` (JS/CSS assets, CodeMirror). The editor posts to `/render-api`, `/render-api/can`, `/render-api/tap`, etc.
- **Runtime Assets**: `local_pg_files/` is the writable mount for user problems; `logs/` holds render logs; `render_app.conf.dist` is the base config (copy to `render_app.conf`).

## Request Flow (Render API)
1) Client/Editor `POST /render-api` with `sourceFilePath` or base64 `problemSource`, `problemSeed`, `outputFormat`, flags. Default output format is `classic`; seed defaults to a random int if omitted.
2) `RenderApp::Controller::RenderProblem::process_pg_file` resolves the source, merges defaults, and invokes `process_problem`.
3) `standaloneRenderer` (inside `RenderProblem`) builds a fake course/user env, sets display options, and calls `WeBWorK::PG->new` with the PG engine.
4) `FormatRenderedProblem` maps the PG result into an HTML template (`WebworkClient/*_format.pl`) and returns JSON (rendered HTML + metadata).

## File IO Flows
- **Load**: `/render-api/tap` -> `IO::raw` -> `Model::Problem->load` from `read_path`.
- **Save**: `/render-api/can` -> `IO::writer` -> `Model::Problem->save`; writes are constrained to `private/` paths.
- **Catalog/Search**: `/render-api/cat` and `/render-api/find` spawn subprocess traversals rooted in `private/` or OPL paths with depth guards.

## Configuration & Defaults
- Env vars set in `RenderApp.pm` (`RENDER_ROOT`, `WEBWORK_ROOT`, `OPL_DIRECTORY`, `MOJO_CONFIG`). Copy `render_app.conf.dist` to override (CORS, JWT secrets, baseURL/formURL, cache headers).
- Service defaults: `MOJO_MODE=development`, port `3000`, `outputFormat=classic`, random seed if missing, MathJax display.
- Non-goals: LMS integration, grading pipelines, or production deployment; k8 manifests are legacy/optional.

## Operational Notes
- For dev without containers: `MOJO_MODE=development morbo -l http://*:3000 script/render_app`.
- Smoke: `script/smoke.sh` (requires running server; hits `/health` and `/render-api`).
- Vendor PG/WeBWorK code is heavy; prefer wrapping rather than editing unless you need engine changes.
